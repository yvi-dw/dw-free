#!/usr/bin/perl
#
# DW::User::Notes - Contains logic for handling notes about users
#
# Authors:
#      Yvi <yvi.dreamwidth@googlemail.com>
#
# Copyright (c) 2010 by Dreamwidth Studios, LLC.
#
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. For a copy of the license, please reference
# 'perldoc perlartistic' or 'perldoc perlgpl'.

package DW::User::Notes;

use strict;
use warnings;

*LJ::User::delete_note = \&delete_note;
sub delete_note {
    my ($u, $note_userid ) = @_;

    return undef unless LJ::is_enabled( 'notes' );
    return undef unless $u->get_cap( 'notes' );

    return unless $u->get_note( $note_userid );

    my $sth = $u->prepare( "DELETE FROM usernotes WHERE userid = ? AND note_userid = ?");
    $sth->execute( $u->userid, $note_userid );

    LJ::MemCache::delete([$u->userid, "note:$note_userid"]);

    return 1;
}

*LJ::User::delete_multiple_notes = \&delete_multiple_notes;
sub delete_multiple_notes {
    my ($u, @note_userids ) = @_;

    return undef unless LJ::is_enabled( 'notes' );
    return undef unless $u->get_cap( 'notes' );

    my $sth = $u->prepare( "DELETE FROM usernotes WHERE userid = ? AND note_userid IN (" . join( ", ", ( "?" ) x @note_userids ) . ")" );
    $sth->execute( $u->userid, @note_userids );

    for my $note_userid (@note_userids) {
        LJ::MemCache::delete([$u->userid, "note:$note_userid"]);
    }

    return 1;
}

*LJ::User::get_all_notes = \&get_all_notes;
sub get_all_notes {
    my $u = shift;

    return undef unless LJ::is_enabled( 'notes' );
    return undef unless $u->get_cap( 'notes' );

    my $sth = $u->prepare( "SELECT note_userid, note FROM usernotes WHERE userid = ?");
    $sth->execute( $u->userid );

    my %notes;
    while ( my ( $uid,$note ) = $sth->fetchrow_array ) {
        $notes{$uid} = $note;
    }
    return %notes;
}

# get the note from a userid
*LJ::User::get_note = \&get_note;
sub get_note {
    my ($u, $note_userid ) = @_;

    return undef unless LJ::is_enabled( 'notes' );
    return undef unless $u->get_cap( 'notes' );

    my $memkey = [$u->userid, "note:$note_userid"];
    my $mem_note = LJ::MemCache::get( $memkey );
    return $mem_note if $mem_note;

    my $note_u = LJ::load_userid( $note_userid );
    return unless $note_u;

    my $sth = $u->prepare( "SELECT note FROM usernotes WHERE userid = ? AND note_userid = ?");
    $sth->execute( $u->userid, $note_userid );

    while ( my ( $note ) = $sth->fetchrow_array ) {
        LJ::MemCache::set( $memkey, $note, 3600 );
        return $note;
    }


}

*LJ::User::set_multiple_notes = \&set_multiple_notes;
# pass hashref userid->note
sub set_multiple_notes {
    my ( $u, $notes ) = @_;
    
    return unless LJ::is_enabled( 'notes' );
    return unless $u->get_cap( 'notes' );

    my $users = LJ::load_userids( keys %{$notes} );

    my $memkey;
    while ( my ( $note_userid, $nu ) = each( %$users ) ) {
        my $note = $notes->{$note_userid};

        my $memkey = [$u->userid, "note:$note_userid"];
        LJ::MemCache::delete( $memkey );

        my $sth = $u->prepare( "REPLACE INTO usernotes (userid, note_userid, note) VALUES ( ?, ?, ? )");
        $sth->execute( $u->userid, $note_userid, $note );

        LJ::MemCache::set( $memkey, $note, 3600 );
    }

    return 1;
}

*LJ::User::set_note = \&set_note;
sub set_note {
    my ($u, $note_userid, $note ) = @_;

    return unless LJ::is_enabled( 'notes' );
    return unless $u->get_cap( 'notes' );

    my $note_u = LJ::load_userid( $note_userid );
    return unless $note_u;

    my $memkey = [$u->userid, "note:$note_userid"];
    LJ::MemCache::delete( $memkey );

    $note = LJ::ehtml( $note );
    return unless $note;

    my $sth = $u->prepare( "REPLACE INTO usernotes (userid, note_userid, note) VALUES ( ?, ?, ? )");
    #return $rollback->() if $u->err || ! $sth;
    $sth->execute( $u->userid, $note_userid, $note );

    LJ::MemCache::set( $memkey, $note, 3600 );
    return $note;
}
1;

#!/usr/bin/perl
#
# DW::Controller::Manage::Notes
#
# This controller is for notes
#
# Authors:
#      Yvi <yvi.dreamwidth@gmail.com>
#
# Copyright (c) 2011 by Dreamwidth Studios, LLC.
#
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. For a copy of the license, please reference
# 'perldoc perlartistic' or 'perldoc perlgpl'.

package DW::Controller::Manage::Notes;

use strict;
use warnings;
use DW::Controller;
use DW::Routing;
use DW::Template;
use DW::User::Notes;

DW::Routing->register_string( "/manage/notes", \&notes_handler, app => 1 );

sub notes_handler {
    my ( $opts ) = @_;

    my $r = DW::Request->get;

    my ( $ok, $rv ) = controller();
    return $rv unless $ok;
    
    my $remote = LJ::get_remote();
    my %notes = $remote->get_all_notes;

    if ( $r->did_post ) {
	    my $args = $r->post_args;

        # set the new notes
        my $id = 1;
        my $inputname = "username_" . $id;
        my $inputnote;
        my %notes_to_set;

        while ( $args->{$inputname} ) {
            my $notes_u = LJ::load_user_or_identity ( $args->{$inputname} );
            if ( $notes_u ) {
                my $notes_userid = $notes_u->userid;
                my $inputnote = "note_" . $id;
                my $note = $args->{$inputnote};
                next unless $note && $notes_userid;
                $notes_to_set{$notes_userid} = $note;
            }
            $id++;
            $inputname = "username_" . $id;
        }

        my @notes_to_delete;
	    for my $userid ( keys %notes ) {
            my $note_username = LJ::get_username( $userid );

            # look for edited notes
            my $notestring = "note_" . $note_username;
            if ( $args->{$notestring} &&  ( $args->{$notestring} ne $notes{$userid} ) ) {
                $notes_to_set{$userid} = $args->{$notestring};
            } 

            unless ( $args->{$notestring} ) {
                push @notes_to_delete, $userid;
            }

            # delete those notes that are supposed to be deleted
	        my $delstring = "delete_" . $note_username;
    	    if ( $args->{$delstring} ) {
	    	    push @notes_to_delete, $userid;
            }
	    }

        $remote->set_multiple_notes( \%notes_to_set );
        $remote->delete_multiple_notes( @notes_to_delete );
        %notes = $remote->get_all_notes();
	    $rv->{saved} = 1;
    }

    if ( %notes ) {
        my @notes_det;
        my $us = LJ::load_userids( keys %notes );
	    # convert for display
	    for my $uid ( keys %notes ) {
	        my $display_u = $us->{$uid};
            next unless $display_u;
            my $username = $display_u->username;

            push @notes_det,
            { 
                username => $display_u->username, 
                usertag => $display_u->ljuser_display,
                note => $notes{$uid}
            };
        }

        $rv->{notes} = \@notes_det;
    }

    return DW::Template->render_template( 'manage/notes.tt', $rv );
}
1;

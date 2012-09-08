#!/usr/bin/perl
use strict;
use warnings;

use lib "$ENV{LJHOME}/cgi-bin";
require 'ljlib.pl';
use LJ::Test qw (temp_user);

use Test::More;
plan tests => 13;

my $u1 = temp_user();
my $u1_id = $u1->userid;
my $u2 = temp_user();
my $u2_id = $u2->userid;
my $u3 = temp_user();
my $u3_id = $u3->userid;

note( "-- initialized" );
{
    ok( ! $u1->get_note( $u2_id ), "no note yet" );
}

note( "-- setting and deleting one note" );
{
    ok ( $u1->set_note( $u2_id, "testnote"), "note set" );
    is ( $u1->get_note( $u2_id), "testnote", "note set correctly" );
    ok ( ! $u2->get_note( $u1_id ), "setting note user1->user 2 does not equal user2->user1" );

    my %all_notes = $u1->get_all_notes;
    is ( keys( %all_notes ), 1, "exactly one note set" );
    is ( $all_notes{$u2_id}, "testnote", "note correctly in full notes set" );
    $u1->set_note( $u2_id, "testnoteedit");
    is ( $u1->get_note( $u2_id), "testnoteedit", "edited one note" );

    ok ( ! $u1->delete_note( $u3_id ), "deleting a not existing note fails" );
    ok ( $u1->delete_note( $u2_id ), "deleted note not found" );
    %all_notes = $u1->get_all_notes;
    is ( keys( %all_notes ), 0, "no notes found after deletion" );
}

note( "-- setting, editing and deleting multiple note" );
{
    $u1->set_note ( $u2_id, "newtestnote");
    is ( $u1->get_note( $u2_id), "newtestnote", "test note set correctly after delete" );
    $u1->set_note ( $u3_id, "testnote2");
    my %all_notes = $u1->get_all_notes;
    is ( keys( %all_notes ), 2, "two notes set" );
    # delete multiple notes
    $u1->delete_multiple_notes( ( $u2_id, $u3_id ) );
    %all_notes = $u1->get_all_notes;
    is ( keys( %all_notes ), 0, "multiple notes deleted" );
}
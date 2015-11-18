#!/usr/bin/env perl

use warnings;
use strict;

use IO::File;

my $schedule_file=$ARGV[0];
my $schedule_fh=IO::File->new($schedule_file, 'r');

#my %current_standings;
my @weeks;
until($schedule_fh->eof()) {
    my $line;
    until(($line && $line=~/^Period/) || $schedule_fh->eof()) {
        $line=$schedule_fh->getline;
    }

    # We got the period line. Get the week off it
    my ($week)=($line=~/^Period (\d+)/);

    # The next 6 weeks should be the matchups
    my $matchups=0;
    my %week_points;
    while($matchups<6 && !$schedule_fh->eof()) {
        my $matchup_line=$schedule_fh->getline();
        chomp $matchup_line;
        my ($team1u, $team2u, $score)=split(/\t/, $matchup_line);
        my $team1=parse_team_name($team1u);
        my $team2=parse_team_name($team2u);
        my ($team1score, $team2score)=split(/ - /, $score);

        $week_points{$team1}=$team1score;
        $week_points{$team2}=$team2score;

        $matchups++;
    }
    push @weeks, \%week_points;
}


my $new_schedule_file=$ARGV[1];
my $new_schedule_fh=IO::File->new($new_schedule_file, 'r');

my %standings;
until($new_schedule_fh->eof()) {
    my $week_line;
    until(($week_line && $week_line=~/^Week/) || $new_schedule_fh->eof()) {
        $week_line=$new_schedule_fh->getline;
    }

    my @matchups;
    while(@matchups<6 && !$new_schedule_fh->eof()) {
        my $matchup_line=$new_schedule_fh->getline();
        chomp $matchup_line;
        my ($team1, $team2)=split(/ vs\. /, $matchup_line);
        print qq(***$team1***$team2***\n);
        push @matchups, [$team1, $team2];
    }

    my $week_result_ref=shift @weeks;
    foreach my $matchup (@matchups) {
        my ($team1, $team2)=@$matchup;
        my $team1score=$week_result_ref->{$team1};
        my $team2score=$week_result_ref->{$team2};

        record_wins_and_losses($team1, $team1score,
                               $team2, $team2score,
                               \%standings,
                              );
    }
}

print_out_standings(\%standings);

sub parse_team_name {
    my $line=shift;
    my ($team_name)=($line=~/^(.*) \(/);
    return $team_name;
}

sub record_wins_and_losses {
    my ($team1, $team1score, $team2, $team2score, $results)=@_;

    #print "$team1\t$team1score\t$team2\t$team2score\n";
    my ($loser, $winner);
    if($team1score>$team2score) {
        $winner=$team1;
        $loser=$team2;
    } else {
        $winner=$team2;
        $loser=$team1;
    }

    $results->{$winner}{wins}++;
    $results->{$loser}{losses}++;
}

sub print_out_standings {
    my $standings_ref=shift;

    my @names=keys %{$standings_ref};
    my @sorted_names=
      sort {$standings_ref->{$b}{wins} <=> $standings_ref->{$a}{wins}}
      @names;

    foreach my $team_name (@sorted_names) {
        printf("%-60s\t%d\t%d\n", $team_name,
               $standings_ref->{$team_name}{wins},
               $standings_ref->{$team_name}{losses},
              );
    }

}

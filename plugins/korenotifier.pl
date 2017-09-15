############################################################
# KoreNotifier plugin by alisonrag
# Plugin to notify your Android SmartPhone when Kore perform predefined actions
# TODO:
# make a todo.
# Copyright (c) 2017-2XXX Development Team
############################################################

package KoreNotifier;

use strict;
use Plugins;
use lib $Plugins::current_plugin_folder;
use Utils qw(existsInList getFormattedDate timeOut);
use Time::HiRes qw(time);
use Log qw(warning message error debug);
use Misc;
use Globals;
use I18N qw(bytesToString);


Plugins::register('KoreNotifier', 'automatically notify your Android SmartPhone when Kore perform predefined actions', \&Unload);

my $base_hooks = Plugins::addHooks(
	['postloadfiles', \&checkConfig],
	['configModify',  \&checkConfig]
);

use constant {
	PLUGIN_NAME	=>	"KoreNotifier",	
	DEFAULT_TIMEOUT => 10,	
	INACTIVE => 0,
	ACTIVE => 1
};

my $korenotifier_hooks;
my $status = INACTIVE;
my $time = time;

sub Unload {
	Plugins::delHook($base_hooks);
	changeStatus(INACTIVE);
	message "[".PLUGIN_NAME."] Plugin unloading or reloading.\n", 'success';
}

sub checkConfig {
	if (exists $config{PLUGIN_NAME.'_on'} && $config{PLUGIN_NAME.'_on'} == 1) {
		message "[".PLUGIN_NAME."] Config set to 'on' ".PLUGIN_NAME." will be active.\n", 'success';
		return changeStatus(ACTIVE);
	} else {
		return changeStatus(INACTIVE);
	}
}

sub changeStatus {
	my $new_status = shift;
	
	return if ($new_status == $status);
	
	if ($new_status == INACTIVE) {
		Plugins::delHook($korenotifier_hooks);
		debug "[".PLUGIN_NAME."] Plugin stage changed to 'INACTIVE'\n", PLUGIN_NAME, 1;		
		
	} elsif ($new_status == ACTIVE) {
		$korenotifier_hooks = Plugins::addHooks(
			['in_game', 				\&in_game],
			['disconnected',			\&disconnected],
			['self_died',				\&self_died],
			['base_level_changed',		\&base_level_changed],
			['job_level_changed',		\&job_level_changed],
			['Network::Receive::map_changed',		\&map_changed],			
			['packet/deal_request',		\&deal_request],
			['packet/party_invite',		\&party_invite],
			['packet/friend_request',	\&friend_request],			
		);
		debug "[".PLUGIN_NAME."] Plugin stage changed to 'ACTIVE'\n", PLUGIN_NAME, 1;		
	}
	
	$status = $new_status;
}

sub korenotifier {
	my ($reason, $message, $priority) = @_;
	my $final_message = $message."\n";
	my $server = $config{master};	
	$final_message .= $server." - ".$config{username};
	require LWP::UserAgent;
	LWP::UserAgent->new()->post(
	  'https://www.meusite.net/api/messages.php' , [
	  "token" => 'YOUR_TOKEN',
	  "user" => 'YOUR_USERNAME',
	  "message" => $final_message,
	  "title" => $reason,
	  "priority" => $priority,	  
	  "timestamp" => int(time)
	]);
	return;
}

sub in_game {
	return if !timeOut($time, DEFAULT_TIMEOUT);
	message "[".PLUGIN_NAME."] Sending Info about in_game Status \n";
	korenotifier("Openkore Status Changed to: IN GAME", "", 1);
	$time = time;
}

sub disconnected {
	return if !timeOut($time, DEFAULT_TIMEOUT);
	message "[".PLUGIN_NAME."] Sending Info about disconnected Status \n";	
	korenotifier("Openkore Status Changed to: DISCONNECTED", "", 1);
	$time = time;
}

sub self_died {
	return if !timeOut($time, DEFAULT_TIMEOUT);
	message "[".PLUGIN_NAME."] Sending Info about self_died Status \n";	
	korenotifier("The ".$char->{name}." DIED in ".$field->name, "", 1);
	$time = time;
}

sub base_level_changed {
	my ($self, $args) = @_;
	message "[".PLUGIN_NAME."] Sending Info about base_level_changed \n";	
	korenotifier("The ".$char->{name}." is now in base level ".$args->{level}, "", 1);
}

sub job_level_changed {
	my ($self, $args) = @_;
	message "[".PLUGIN_NAME."] Sending Info about job_level_changed \n";	
	korenotifier("The ".$char->{name}." is now in job level ".$args->{level}, "", 1);
}

sub map_changed {
	my ($self, $args) = @_;
	return unless ($field->name ne $args->{oldMap}); # don't send notification if kore has teleported to the same map
	message "[".PLUGIN_NAME."] Sending Info about map_changed \n";	
	korenotifier("The ".$char->{name}." changed map from: ".$args->{oldMap} . " to: " . $field->name, "", 1);
}

sub deal_request {
	my ($self, $args) = @_;
	my $user = bytesToString($args->{user});
	message "[".PLUGIN_NAME."] Sending Info about deal_request \n";	
	korenotifier($user ." is trying  to deal with ".$char->{name}, "", 1);
}

sub party_invite {
	my ($self, $args) = @_;
	my $party_name = bytesToString($args->{name});
	message "[".PLUGIN_NAME."] Sending Info about party_invite \n";	
	korenotifier("Incoming Request to join party ".$party_name, "", 1);	
}

sub friend_request {
	my ($self, $args) = @_;
	my $incoming_friend_name = bytesToString($args->{name});
	korenotifier($incoming_friend_name." wants to be your friend", $incomingFriend{'name'});
}

1;
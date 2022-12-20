# @summary Install slack-mastodon service
#
# @param mastodon_server sets the Mastodon server to connect to
# @param mastodon_access_token sets the token to use for Mastodon API auth
# @param slack_channel sets the Slack channel to publish to
# @param slack_bot_token sets the bot token for the Slack API
# @param version sets the slack-mastodon tag to use
class slackmastodon (
  String $mastodon_server,
  String $mastodon_access_token,
  String $slack_channel,
  String $slack_bot_token,
  String $version = 'v0.0.1',
) {
  $arch = $facts['os']['architecture'] ? {
    'x86_64'  => 'amd64',
    'arm64'   => 'arm64',
    'aarch64' => 'arm64',
    'arm'     => 'arm',
    default   => 'error',
  }

  $binfile = '/usr/local/bin/slack-mastodon'
  $filename = "slack-mastodon_${downcase($facts['kernel'])}_${arch}"
  $filename = "goatcounter-dev-linux-${arch}.gz"
  $url = "https://github.com/akerl/slack-mastodon/releases/download/${version}/${filename}"

  group { 'slackmastodon':
    ensure => present,
    system => true,
  }

  user { 'slackmastodon':
    ensure => present,
    system => true,
    gid    => 'slackmastodon',
    shell  => '/usr/bin/nologin',
    home   => '/var/lib/slackmastodon',
  }

  exec { 'download goatcounter':
    command => "/usr/bin/curl -sLo '${binfile}' '${url}' && chmod a+x '${binfile}'",
    unless  => "${binfile} version | grep '${version}'",
  }

  file { [
      '/var/lib/slackmastodon',
      '/var/lib/slackmastodon/.config',
      '/var/lib/slackmastodon/.config/slackmastodon',
    ]:
      ensure => directory,
      owner  => 'slackmastodon',
      group  => 'slackmastodon',
      mode   => '0750',
  }

  file { '/var/lib/slackmastodon/.config/slackmastodon/config.yml':
    ensure  => file,
    mode    => '0640',
    owner   => 'slackmastodon',
    group   => 'slackmastodon',
    content => template('slackmastodon/config.yml.erb'),
  }

  file { '/etc/systemd/system/slack-mastodon.service':
    ensure => file,
    source => 'puppet:///modules/goat/slack-mastodon.service',
  }

  file { '/etc/systemd/system/slack-mastodon.timer':
    ensure  => file,
    content => template('slackmastodon/slack-mastodon.timer.erb'),
  }

  ~> service { 'slack-mastodon.timer':
    ensure  => running,
    enable  => true,
    require => File['/var/lib/slackmastodon/.config/slackmastodon/config.yml'],
  }
}

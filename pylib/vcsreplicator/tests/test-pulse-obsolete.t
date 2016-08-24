#require hgmodocker

  $ . $TESTDIR/pylib/vcsreplicator/tests/helpers.sh
  $ vcsrenv

  $ pulse create-queue exchange/hgpushes/v1 v1
  $ pulse create-queue exchange/hgpushes/v2 v2

  $ standarduser

Obsolescence markers are turned into pulse events

  $ hgmo create-repo obs scm_level_1
  (recorded repository creation in replication log)
  $ hgmo exec hgssh /set-hgrc-option obs phases publish false
  $ hgmo exec hgssh /set-hgrc-option obs experimental evolution all
  $ hgmo exec hgssh /var/hg/venv_pash/bin/hg -R /repo/hg/mozilla/obs replicatehgrc
  recorded hgrc in replication log

  $ hg -q clone ssh://${SSH_SERVER}:${SSH_PORT}/obs obs
  $ cd obs
  $ cat >> .hg/hgrc << EOF
  > [extensions]
  > rebase =
  > [experimental]
  > evolution = all
  > EOF

  $ touch foo
  $ hg -q commit -A -m initial
  $ hg phase --public -f -r .
  $ hg -q push
  $ touch file0
  $ hg -q commit -A -m file0
  $ touch file1
  $ hg -q commit -A -m file1
  $ hg -q push

There is a race between multiple repo events and the pulse consumer processing
them. So disable the pulse consumer until all repo changes have been made.

  $ hgmo exec hgssh supervisorctl stop pulsenotifier
  pulsenotifier: stopped

  $ hg rebase -s . -d 0
  rebasing 2:4da703b7f59b "file1" (tip)
  $ hg push -f
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT/obs
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: added 1 changesets with 0 changes to 1 files (+1 heads)
  remote: recorded push in pushlog
  remote: 1 new obsolescence markers
  remote: 
  remote: View your change here:
  remote:   https://hg.mozilla.org/obs/rev/7d683ce4e561
  remote: recorded changegroup in replication log in \d+\.\d+s (re)
  remote: recorded updates to obsolete in replication log in \d+\.\d+s (re)

  $ hg debugobsolete
  4da703b7f59b720f524f709aa07eed3182ba1acd 7d683ce4e5618b7a0a7033b4d27f6c28b2c0f7c2 0 (*) {'user': 'Test User <someone@example.com>'} (glob)

  $ hgmo exec hgweb0 /var/hg/venv_replication/bin/vcsreplicator-consumer --wait-for-no-lag /etc/mercurial/vcsreplicator.ini
  $ hgmo exec hgweb1 /var/hg/venv_replication/bin/vcsreplicator-consumer --wait-for-no-lag /etc/mercurial/vcsreplicator.ini

  $ hgmo exec hgssh /var/hg/venv_pash/bin/hg -R /repo/hg/mozilla/obs debugobsolete 7d683ce4e5618b7a0a7033b4d27f6c28b2c0f7c2
  no username found, using 'root@*' instead (glob)
  recorded updates to obsolete in replication log in \d+\.\d+s (re)

  $ hgmo exec hgssh /var/hg/venv_pash/bin/hg -R /repo/hg/mozilla/obs debugobsolete
  4da703b7f59b720f524f709aa07eed3182ba1acd 7d683ce4e5618b7a0a7033b4d27f6c28b2c0f7c2 0 (*) {'user': 'Test User <someone@example.com>'} (glob)
  7d683ce4e5618b7a0a7033b4d27f6c28b2c0f7c2 0 (*) {'user': 'root@*'} (glob)

  $ hgmo exec hgweb0 /var/hg/venv_replication/bin/vcsreplicator-consumer --wait-for-no-lag /etc/mercurial/vcsreplicator.ini
  $ hgmo exec hgweb1 /var/hg/venv_replication/bin/vcsreplicator-consumer --wait-for-no-lag /etc/mercurial/vcsreplicator.ini
  $ hgmo exec hgssh supervisorctl start pulsenotifier
  pulsenotifier: started
  $ sleep 2

  $ pulseconsumer --wait-for-no-lag

  $ pulse dump-messages exchange/hgpushes/v2 v2
  - _meta:
      exchange: exchange/hgpushes/v2
      routing_key: obs
    data:
      repo_url: https://hg.mozilla.org/obs
    type: newrepo.1
  - _meta:
      exchange: exchange/hgpushes/v2
      routing_key: obs
    data:
      heads:
      - 77538e1ce4bec5f7aac58a7ceca2da0e38e90a72
      pushlog_pushes:
      - push_full_json_url: https://hg.mozilla.org/obs/json-pushes?version=2&full=1&startID=0&endID=1
        push_json_url: https://hg.mozilla.org/obs/json-pushes?version=2&startID=0&endID=1
        pushid: 1
        time: \d+ (re)
        user: user@example.com
      repo_url: https://hg.mozilla.org/obs
      source: serve
    type: changegroup.1
  - _meta:
      exchange: exchange/hgpushes/v2
      routing_key: obs
    data:
      heads:
      - 4da703b7f59b720f524f709aa07eed3182ba1acd
      pushlog_pushes:
      - push_full_json_url: https://hg.mozilla.org/obs/json-pushes?version=2&full=1&startID=1&endID=2
        push_json_url: https://hg.mozilla.org/obs/json-pushes?version=2&startID=1&endID=2
        pushid: 2
        time: \d+ (re)
        user: user@example.com
      repo_url: https://hg.mozilla.org/obs
      source: serve
    type: changegroup.1
  - _meta:
      exchange: exchange/hgpushes/v2
      routing_key: obs
    data:
      heads:
      - 7d683ce4e5618b7a0a7033b4d27f6c28b2c0f7c2
      pushlog_pushes:
      - push_full_json_url: https://hg.mozilla.org/obs/json-pushes?version=2&full=1&startID=2&endID=3
        push_json_url: https://hg.mozilla.org/obs/json-pushes?version=2&startID=2&endID=3
        pushid: 3
        time: \d+ (re)
        user: user@example.com
      repo_url: https://hg.mozilla.org/obs
      source: serve
    type: changegroup.1
  - _meta:
      exchange: exchange/hgpushes/v2
      routing_key: obs
    data:
      markers:
      - precursor:
          desc: file1
          known: true
          node: 4da703b7f59b720f524f709aa07eed3182ba1acd
          push:
            push_full_json_url: https://hg.mozilla.org/obs/json-pushes?version=2&full=1&startID=1&endID=2
            push_json_url: https://hg.mozilla.org/obs/json-pushes?version=2&startID=1&endID=2
            pushid: 2
            time: \d+ (re)
            user: user@example.com
          visible: false
        successors:
        - desc: file1
          known: true
          node: 7d683ce4e5618b7a0a7033b4d27f6c28b2c0f7c2
          push:
            push_full_json_url: https://hg.mozilla.org/obs/json-pushes?version=2&full=1&startID=2&endID=3
            push_json_url: https://hg.mozilla.org/obs/json-pushes?version=2&startID=2&endID=3
            pushid: 3
            time: \d+ (re)
            user: user@example.com
          visible: false
        time: \d+\.\d+ (re)
        user: Test User <someone@example.com>
      repo_url: https://hg.mozilla.org/obs
    type: obsolete.1
  - _meta:
      exchange: exchange/hgpushes/v2
      routing_key: obs
    data:
      markers:
      - precursor:
          desc: file1
          known: true
          node: 7d683ce4e5618b7a0a7033b4d27f6c28b2c0f7c2
          push:
            push_full_json_url: https://hg.mozilla.org/obs/json-pushes?version=2&full=1&startID=2&endID=3
            push_json_url: https://hg.mozilla.org/obs/json-pushes?version=2&startID=2&endID=3
            pushid: 3
            time: \d+ (re)
            user: user@example.com
          visible: false
        successors: []
        time: \d+\.\d+ (re)
        user: root@* (glob)
      repo_url: https://hg.mozilla.org/obs
    type: obsolete.1

  $ cd ..

Cleanup

  $ hgmo clean
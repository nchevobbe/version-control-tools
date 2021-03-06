#require hgmodocker

  $ . $TESTDIR/hghooks/tests/common.sh
  $ . $TESTDIR/hgserver/tests/helpers.sh
  $ hgmoenv
  $ hgmo create-repo not-mozilla-central scm_level_3
  (recorded repository creation in replication log)
  $ hgmo create-repo project scm_project
  (recorded repository creation in replication log)
  $ hgmo exec hgssh /set-hgrc-option project mozilla lando_required_repo_list project
  $ hgmo exec hgssh /set-hgrc-option project mozilla direct_push_disabled_repo_list project
  $ scm4user
  $ hg clone ssh://${SSH_SERVER}:${SSH_PORT}/not-mozilla-central client
  no changes found
  updating to branch default
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ cd client

Pushing to not-mozilla-central should succeed if user has "scm_allow_direct_push" (scm level 4)

  $ touch foo
  $ hg commit -A -m 'a new file'
  adding foo
  $ hg push
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT/not-mozilla-central
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: recorded push in pushlog
  remote: added 1 changesets with 1 changes to 1 files
  remote: 
  remote: View your change here:
  remote:   https://hg.mozilla.org/not-mozilla-central/rev/57a078f147413eada087f5d2ace88598c06d2c42
  remote: recorded changegroup in replication log in *s (glob)


  $ cd ..
  $ scm3user
  $ hg clone ssh://${SSH_SERVER}:${SSH_PORT}/not-mozilla-central client2
  requesting all changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  new changesets 57a078f14741
  updating to branch default
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved


  $ cd client2

Pushing to not-mozilla-central should fail if the SCM_LEVEL_3 user has 
provided neither MAGIC_WORDS nor a justification in their top commit.

  $ echo closed > foo
  $ hg commit -m 'this should fail'
  $ hg push
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT/not-mozilla-central
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: 
  remote: *********************************** ERROR ***********************************
  remote: Pushing directly to this repo is disallowed, please use Lando.
  remote: To override, in your head commit, include the literal string, "MANUAL PUSH:",
  remote: followed by a sentence of justification.
  remote: *****************************************************************************
  remote: 
  remote: transaction abort!
  remote: rollback completed
  remote: pretxnchangegroup.mozhooks hook failed
  abort: push failed on remote
  [255]


Pushing to not-mozilla-central should succeed if the user has SCM_LEVEL_3 and
magic words with justification

  $ hg commit --amend -q -m 'MANUAL PUSH: because I want to'
  $ hg push
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT/not-mozilla-central
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: l3user@example.com pushed: "because I want to". (not-mozilla-central@ce3b4a58cd35, SCM_LEVEL_3)
  remote: recorded push in pushlog
  remote: added 1 changesets with 1 changes to 1 files
  remote: 
  remote: View your change here:
  remote:   https://hg.mozilla.org/not-mozilla-central/rev/ce3b4a58cd35be233796dbc19347bc77c72da472
  remote: recorded changegroup in replication log in *s (glob)


Pushing multiple changesets to not-mozilla-central is accepted if the user has
SCM_LEVEL_3 and the magic words and justification are on the top commit.

  $ echo dummy0 > foo
  $ hg commit -m 'dummy0'
  $ echo dummy1 >> foo
  $ hg commit -m 'dummy1'
  $ echo dummy2 >> foo
  $ hg commit -m 'dummy2'
  $ echo forceit >> foo
  $ hg commit -m 'MANUAL PUSH: because I can'
  $ hg push
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT/not-mozilla-central
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: l3user@example.com pushed: "because I can". (not-mozilla-central@1235dd2aeaf5, SCM_LEVEL_3)
  remote: recorded push in pushlog
  remote: added 4 changesets with 4 changes to 1 files
  remote: 
  remote: View your changes here:
  remote:   https://hg.mozilla.org/not-mozilla-central/rev/0c601082542dc49efb346c2a5d527d2ff25d35fe
  remote:   https://hg.mozilla.org/not-mozilla-central/rev/c2b4c0af8709609146bb57b7db7581b5dfb2a5af
  remote:   https://hg.mozilla.org/not-mozilla-central/rev/4da11b4f9cb4f0fd8a81d444450a6510c8d33d8c
  remote:   https://hg.mozilla.org/not-mozilla-central/rev/1235dd2aeaf5c77422c9bff30f39a2150181bd63
  remote: recorded changegroup in replication log in *s (glob)

Pushing multiple changesets to not-mozilla-central should fail if the user has
SCM_LEVEL_3 and the magic words on the top commit, but justification is missing.

  $ echo dummy4 >> foo
  $ hg commit -m 'dummy4'
  $ echo dummy5 >> foo
  $ hg commit -m 'dummy5'
  $ echo "no justification" >> foo
  $ hg commit -m 'MANUAL PUSH:'
  $ hg push
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT/not-mozilla-central
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: 
  remote: *********************************** ERROR ***********************************
  remote: Pushing directly to this repo is disallowed, please use Lando.
  remote: To override, in your head commit, include the literal string, "MANUAL PUSH:",
  remote: followed by a sentence of justification.
  remote: *****************************************************************************
  remote: 
  remote: transaction abort!
  remote: rollback completed
  remote: pretxnchangegroup.mozhooks hook failed
  abort: push failed on remote
  [255]

Pushing multiple changesets to not-mozilla-central should fail if the user has
SCM_LEVEL_3 and the magic words & justification are on the wrong commit.

  $ echo dummy6 >> foo
  $ hg commit -m 'dummy6'
  $ echo "justification in wrong commit" >> foo
  $ hg commit -m 'MANUAL PUSH: at least I tried'
  $ echo dummy7 >> foo
  $ hg commit -m 'dummy7'
  $ hg push
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT/not-mozilla-central
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: 
  remote: *********************************** ERROR ***********************************
  remote: Pushing directly to this repo is disallowed, please use Lando.
  remote: To override, in your head commit, include the literal string, "MANUAL PUSH:",
  remote: followed by a sentence of justification.
  remote: *****************************************************************************
  remote: 
  remote: transaction abort!
  remote: rollback completed
  remote: pretxnchangegroup.mozhooks hook failed
  abort: push failed on remote
  [255]

  $ cd ..
  $ standarduser
  $ hg clone ssh://${SSH_SERVER}:${SSH_PORT}/not-mozilla-central client3
  requesting all changes
  adding changesets
  adding manifests
  adding file changes
  added 6 changesets with 6 changes to 1 files
  new changesets 57a078f14741:1235dd2aeaf5
  updating to branch default
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved


  $ cd client3

Pushing to not-mozilla-central should fail for a SCM_LEVEL_1 user.

  $ echo closed > foo
  $ hg commit -m 'this should fail'
  $ hg push
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT/not-mozilla-central
  searching for changes
  remote: abort: could not lock working directory of /repo/hg/mozilla/not-mozilla-central: Permission denied
  abort: stream ended unexpectedly (got 0 bytes, expected 4)
  [255]

  $ cd ..
  $ scm_project_user
  $ hg clone ssh://${SSH_SERVER}:${SSH_PORT}/project client4
  no changes found
  updating to branch default
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ cd client4

Pushing to project should fail if the SCM_PROJECT user has 
provided neither MAGIC_WORDS nor a justification in their top commit.

  $ touch foo
  $ hg commit -A -m 'this should fail'
  adding foo
  $ hg push
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT/project
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: 
  remote: *********************************** ERROR ***********************************
  remote: Pushing directly to this repo is disallowed, please use Lando.
  remote: To override, in your head commit, include the literal string, "MANUAL PUSH:",
  remote: followed by a sentence of justification.
  remote: *****************************************************************************
  remote: 
  remote: transaction abort!
  remote: rollback completed
  remote: pretxnchangegroup.mozhooks hook failed
  abort: push failed on remote
  [255]

Pushing to project should succeed if the user has SCM_PROJECT and
magic words with justification

  $ hg commit --amend -q -m 'MANUAL PUSH: because I want to'
  $ hg push
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT/project
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: project_user@example.com pushed: "because I want to". (project@5d1da14daca6, SCM_PROJECT)
  remote: recorded push in pushlog
  remote: added 1 changesets with 1 changes to 1 files
  remote: 
  remote: View your change here:
  remote:   https://hg.mozilla.org/project/rev/5d1da14daca6a78e2e6b21f6cfbffbe417ae54f9
  remote: recorded changegroup in replication log in *s (glob)


  $ cd ..
  $ scm4_project_user
  $ hg clone ssh://${SSH_SERVER}:${SSH_PORT}/project client5
  requesting all changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  new changesets 5d1da14daca6
  updating to branch default
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved


  $ cd client5

Pushing to project should fail if the SCM_PROJECT user with SCM_ALLOW_DIRECT_PUSH has 
provided neither MAGIC_WORDS nor a justification in their top commit.

  $ echo closed > foo
  $ hg commit -m 'this should fail'
  $ hg push
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT/project
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: 
  remote: *********************************** ERROR ***********************************
  remote: Pushing directly to this repo is disallowed, please use Lando.
  remote: To override, in your head commit, include the literal string, "MANUAL PUSH:",
  remote: followed by a sentence of justification.
  remote: *****************************************************************************
  remote: 
  remote: transaction abort!
  remote: rollback completed
  remote: pretxnchangegroup.mozhooks hook failed
  abort: push failed on remote
  [255]

Pushing to project should succeed if the user has SCM_PROJECT and
magic words with justification

  $ hg commit --amend -q -m 'MANUAL PUSH: because I want to'
  $ hg push
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT/project
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: direct_project_user@example.com pushed: "because I want to". (project@35eba5179e43, SCM_PROJECT)
  remote: recorded push in pushlog
  remote: added 1 changesets with 1 changes to 1 files
  remote: 
  remote: View your change here:
  remote:   https://hg.mozilla.org/project/rev/35eba5179e43c5a6dfc4a790f8ea58a01dd3ae7b
  remote: recorded changegroup in replication log in *s (glob)


  $ cd ..
  $ export AUTOLAND_REQUEST_USER="autolandrequester@example.com"
  $ hgmo create-ldap-user bind-autoland@mozilla.com user1 1500 'Otto Land' --scm-level 4 --key-file autoland --group scm_project
  $ cat >> $HGRCPATH << EOF
  > [ui]
  > ssh = ssh -o "SendEnv AUTOLAND_REQUEST_USER" -F `pwd`/ssh_config -i `pwd`/autoland -l bind-autoland@mozilla.com
  > EOF
  $ hg clone ssh://${SSH_SERVER}:${SSH_PORT}/project client6
  requesting all changes
  adding changesets
  adding manifests
  adding file changes
  added 2 changesets with 2 changes to 1 files
  new changesets 5d1da14daca6:35eba5179e43
  updating to branch default
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved


  $ cd client6

Pushing to project should succeed for an auoland user.

  $ echo opened > foo
  $ hg commit -q -m 'this should succeed'
  $ hg push
  pushing to ssh://$DOCKER_HOSTNAME:$HGPORT/project
  searching for changes
  remote: adding changesets
  remote: adding manifests
  remote: adding file changes
  remote: autoland or landing worker push detected
  remote: recorded push in pushlog
  remote: added 1 changesets with 1 changes to 1 files
  remote: 
  remote: View your change here:
  remote:   https://hg.mozilla.org/project/rev/64ad9f49289f770653c3d533bdd1f5694d7dfe62
  remote: recorded changegroup in replication log in *s (glob)

  $ hgmo clean

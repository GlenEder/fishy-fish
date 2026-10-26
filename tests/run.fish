#!/usr/bin/env fish
# Test suite for the fishy-fish functions. Run with: fish tests/run.fish
# Everything happens in a temp sandbox with a local bare remote; no network access.
# The interactive picker and updateDevroot are also covered by the README checklist.

set -l repo_root (realpath (status dirname)/..)
set -g fish_function_path $repo_root/functions/**/ $fish_function_path

set -g sandbox (mktemp -d)
set -g passes 0
set -g failures 0
set -g orig_devroot $DEVROOT

# Isolate git from the developer's real config
set -gx GIT_CONFIG_GLOBAL $sandbox/gitconfig
set -gx GIT_CONFIG_NOSYSTEM 1
printf '[user]\n\tname = Test\n\temail = test@example.com\n[init]\n\tdefaultBranch = main\n[commit]\n\tgpgsign = false\n[tag]\n\tgpgsign = false\n' > $GIT_CONFIG_GLOBAL

function __cleanup --on-event fish_exit
    test -n "$sandbox"; and rm -rf $sandbox
end

# --- assertion helpers -------------------------------------------------------

function __pass -a name
    set -g passes (math $passes + 1)
    echo "ok: $name"
end

function __fail -a name detail
    set -g failures (math $failures + 1)
    echo "FAIL: $name"
    test -n "$detail"; and echo "      $detail"
end

# Command substitution splits multi-line output into a list; flatten so assertions see all of it
function assert_eq
    set -l name $argv[1]
    set -l expected $argv[2]
    set -l actual (string join ' ' -- $argv[3..-1])
    if test "$expected" = "$actual"
        __pass $name
    else
        __fail $name "expected [$expected], got [$actual]"
    end
end

function assert_contains
    set -l name $argv[1]
    set -l needle $argv[2]
    set -l haystack (string join ' ' -- $argv[3..-1])
    if string match -q -- "*$needle*" "$haystack"
        __pass $name
    else
        __fail $name "expected to contain [$needle], got [$haystack]"
    end
end

function assert_matches
    set -l name $argv[1]
    set -l pattern $argv[2]
    set -l actual (string join ' ' -- $argv[3..-1])
    if string match -q -r -- $pattern "$actual"
        __pass $name
    else
        __fail $name "expected to match [$pattern], got [$actual]"
    end
end

function assert_status
    assert_eq $argv[1] $argv[2] (string join ' ' -- $argv[3..-1])
end

function assert_exists -a name path
    if test -e "$path"
        __pass $name
    else
        __fail $name "expected [$path] to exist"
    end
end

function assert_missing -a name path
    if not test -e "$path"
        __pass $name
    else
        __fail $name "expected [$path] to be gone"
    end
end

function strip_colors -a text
    string replace -ra '\e\[[0-9;]*m' '' -- $text
end

# --- fixtures ----------------------------------------------------------------

function make_repo -a name
    set -l origin $sandbox/$name.git
    git init -q --bare -b main $origin
    git clone -q $origin $sandbox/$name 2>/dev/null
    pushd $sandbox/$name
    echo one > a.txt
    mkdir -p sub
    echo one > sub/b.txt
    git add -A
    git commit -qm init
    git push -q -u origin main
    popd
    echo $sandbox/$name
end

# --- syntax ------------------------------------------------------------------

set -g preexisting
for f in $repo_root/functions/**/*.fish $repo_root/tests/*.fish
    fish -n $f; or set -a preexisting $f
end
assert_eq "all fish files parse" "" "$preexisting"

# --- logging -----------------------------------------------------------------

set -g log_out (strip_colors (log_info hello | string collect))
assert_contains "log_info goes to stdout with INFO prefix" "INFO: hello" $log_out
set -g log_out (strip_colors (log_info -t timed | string collect))
assert_matches "log_info -t adds timestamp" '^\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\] INFO: timed$' $log_out

set -g warn_err (strip_colors (log_warning hello 2>&1 >/dev/null | string collect))
assert_contains "log_warning goes to stderr" "WARN: hello" $warn_err
set -g warn_err (strip_colors (log_warning -t timed 2>&1 >/dev/null | string collect))
assert_matches "log_warning -t adds timestamp" '^\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\] WARN: timed$' $warn_err
set -g warn_out (log_warning hello 2>/dev/null | string collect)
assert_eq "log_warning writes nothing to stdout" "" $warn_out

set -g err_err (strip_colors (log_error boom 2>&1 >/dev/null | string collect))
assert_contains "log_error goes to stderr" "ERROR: boom" $err_err
set -g err_err (strip_colors (log_error -t boom 2>&1 >/dev/null | string collect))
assert_matches "log_error -t adds timestamp" '^\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\] ERROR: boom$' $err_err
set -g err_out (log_error boom 2>/dev/null | string collect)
assert_eq "log_error writes nothing to stdout" "" $err_out

log_info >/dev/null
assert_status "log_info with no message exits 0" 0 $status
set -g empty_out (log_warning 2>/dev/null | string collect)
assert_eq "log_warning with no message prints nothing" "" $empty_out

# --- isNumber ----------------------------------------------------------------

isNumber 123
assert_status "isNumber accepts digits" 0 $status
isNumber 12ab
assert_status "isNumber rejects mixed input" 1 $status

# --- gits / dropChanges ------------------------------------------------------

set -g repo (make_repo repo)
pushd $repo

echo changed >> a.txt
set -g out (gits | string collect)
assert_contains "gits shows modified file with status symbol" " M a.txt" $out
set -g out (gits -f | string collect)
assert_eq "gits -f prints filenames only" "a.txt" $out
gits -h >/dev/null 2>&1
assert_status "gits -h exits 0" 0 $status
gits --bogus >/dev/null 2>&1
assert_status "gits rejects unknown flag" 1 $status

dropChanges >/dev/null
set -g out (gits | string collect)
assert_eq "dropChanges reverts without flags" "" $out

# -d only deletes untracked files at or below the current directory
echo mod >> a.txt
echo root > untracked-root.txt
echo sub > sub/untracked-sub.txt
pushd sub
dropChanges -d >/dev/null
assert_missing "dropChanges -d deletes untracked file in cwd" "$repo/sub/untracked-sub.txt"
assert_exists "dropChanges -d keeps untracked file above cwd" "$repo/untracked-root.txt"
popd
git diff --quiet
assert_status "dropChanges -d leaves tracked changes alone" 1 $status

# -a alone restores tracked files in every directory and keeps untracked files
echo x >> a.txt
echo x >> sub/b.txt
dropChanges -a >/dev/null
git diff --quiet
assert_status "dropChanges -a reverts all tracked changes" 0 $status
assert_exists "dropChanges -a keeps untracked files" "$repo/untracked-root.txt"

# -d -a deletes untracked files outside the current directory as well
pushd sub
dropChanges -d -a >/dev/null
assert_missing "dropChanges -d -a deletes untracked file above cwd" "$repo/untracked-root.txt"
popd
popd

# --- createBranch ------------------------------------------------------------

pushd $repo
echo y | createBranch feature/one >/dev/null 2>&1
assert_status "createBranch succeeds with confirmation" 0 $status
git rev-parse --verify --quiet refs/heads/feature/one >/dev/null
assert_status "createBranch creates local branch" 0 $status
git rev-parse --verify --quiet refs/remotes/origin/feature/one >/dev/null
assert_status "createBranch pushes branch to origin" 0 $status

echo y | createBranch feature/one >/dev/null 2>&1
assert_status "createBranch refuses existing remote branch" 1 $status

createBranch >/dev/null 2>&1
assert_status "createBranch requires an argument" 1 $status

createBranch one two >/dev/null 2>&1
assert_status "createBranch rejects extra arguments" 1 $status

git checkout -q main
popd

# --- deleteOldBranches -------------------------------------------------------

pushd $repo
git branch gone-branch
git push -q -u origin gone-branch
git checkout -q main
git push -q origin --delete gone-branch
deleteOldBranches >/dev/null 2>&1
assert_status "deleteOldBranches exits 0" 0 $status
set -g out (git branch --list gone-branch | string collect)
assert_eq "deleteOldBranches deletes a gone branch" "" $out

# A gone branch checked out in a linked worktree: the worktree is removed first
git branch wt-branch
git push -q -u origin wt-branch
git worktree add -q $sandbox/wt wt-branch
git push -q origin --delete wt-branch
git fetch -qpt
deleteOldBranches >/dev/null 2>&1
assert_status "deleteOldBranches handles worktrees" 0 $status
assert_missing "deleteOldBranches removes the linked worktree" $sandbox/wt
set -g out (git branch --list wt-branch | string collect)
assert_eq "deleteOldBranches deletes the worktree branch" "" $out
popd

# --- master ------------------------------------------------------------------

pushd $repo
git checkout -q -b scratch-branch
master >/dev/null 2>&1
assert_status "master exits 0" 0 $status
assert_eq "master checks out the default branch" "main" (git branch --show-current)

git branch gone-two
git push -q -u origin gone-two
git checkout -q main
git push -q origin --delete gone-two
master >/dev/null 2>&1
set -g out (git branch --list gone-two | string collect)
assert_eq "master cascades into deleteOldBranches" "" $out
popd

# --- checkout picker ---------------------------------------------------------

set -g prepo (make_repo picker)
pushd $prepo
for n in (seq 12)
    git branch b$n
end
git push -q origin b11 b12
git branch remote-only
git push -q origin remote-only
git branch -D remote-only >/dev/null
git fetch -q -p

set -g locals (git branch --format='%(refname:short)')

# Page one holds ten branches, so option 11 is "Show more branches"
printf '11\n1\n' | checkout >/dev/null 2>&1
assert_eq "checkout pages to the next ten branches" $locals[11] (git branch --show-current)

git checkout -q main
# Page two's extra option (4) switches to remote branches; the last one sorts last
set -g remote_count (count (git branch -r --format='%(refname:short)' | string match -rv 'HEAD|^[^/]+$'))
printf '11\n4\n%s\n' $remote_count | checkout >/dev/null 2>&1
assert_eq "checkout strips the remote prefix on selection" "remote-only" (git branch --show-current)

git checkout -q main
printf 'abc\n99\n1\n' | checkout >/dev/null 2>&1
assert_eq "checkout retries after invalid input" $locals[1] (git branch --show-current)

git checkout -q main
checkout </dev/null >/dev/null 2>&1
assert_status "checkout exits non-zero on closed stdin" 1 $status
popd

# --- pwGen -------------------------------------------------------------------

set -g out (pwGen | string collect)
assert_eq "pwGen default length" 32 (string length -- $out)
assert_matches "pwGen emits base64 characters" '^[A-Za-z0-9+/=]+$' $out
set -g out (pwGen -l 8 | string collect)
assert_eq "pwGen honors -l" 8 (string length -- $out)
set -g out (pwGen --length 5 | string collect)
assert_eq "pwGen honors --length" 5 (string length -- $out)
pwGen -l 0 >/dev/null 2>&1
assert_status "pwGen rejects zero length" 1 $status
pwGen -l abc >/dev/null 2>&1
assert_status "pwGen rejects non-numeric length" 1 $status
pwGen -l >/dev/null 2>&1
assert_status "pwGen requires a length value" 1 $status
pwGen --bogus >/dev/null 2>&1
assert_status "pwGen rejects unknown flags" 1 $status

# --- updateDevroot -----------------------------------------------------------

set -g upd_root $sandbox/update
mkdir -p $upd_root
git init -q --bare -b main $upd_root/broken.git
git clone -q $upd_root/broken.git $upd_root/broken 2>/dev/null

# updateDevroot backgrounds work, so capture through a file rather than a pipe
set -g out_file $sandbox/update-devroot.out
updateDevroot -f $sandbox >$out_file 2>&1
assert_status "updateDevroot fetch-only exits 0" 0 $status
set -g out (strip_colors (cat $out_file | string collect))
assert_contains "updateDevroot reports a success count" "succeeded, 0 failed" $out

updateDevroot -f -i picker $sandbox >$out_file 2>&1
assert_status "updateDevroot with an ignored dir exits 0" 0 $status
set -g out (strip_colors (cat $out_file | string collect))
assert_contains "updateDevroot skips ignored directories" "Skipping picker (ignored)" $out

updateDevroot -f -i repo -i picker $sandbox >$out_file 2>&1
set -g out (strip_colors (cat $out_file | string collect))
assert_contains "updateDevroot accepts repeated --ignore-dir" "Skipping repo (ignored)" $out

# A repo with no origin/HEAD cannot be updated to a default branch
updateDevroot $upd_root >$out_file 2>&1
assert_status "updateDevroot reports failures without aborting" 0 $status
set -g out (strip_colors (cat $out_file | string collect))
assert_contains "updateDevroot counts failures" "1 failed" $out
assert_contains "updateDevroot lists failed repos" "Failed repos: broken" $out

set -gx DEVROOT $upd_root
updateDevroot -f >$out_file 2>&1
set -g out (strip_colors (cat $out_file | string collect))
assert_contains "updateDevroot falls back to DEVROOT" "Missing directory argument" $out
assert_contains "updateDevroot uses DEVROOT" "Using $upd_root" $out

set -e DEVROOT
updateDevroot -f >/dev/null 2>&1
assert_status "updateDevroot errors without DEVROOT" 1 $status
set -gx DEVROOT $orig_devroot

updateDevroot -f /nonexistent >/dev/null 2>&1
assert_status "updateDevroot rejects a missing directory" 1 $status
updateDevroot -i >/dev/null 2>&1
assert_status "updateDevroot requires an --ignore-dir value" 1 $status
updateDevroot -z >/dev/null 2>&1
assert_status "updateDevroot rejects unknown flags" 1 $status

# --- summary -----------------------------------------------------------------

echo ""
echo "passed: $passes, failed: $failures"
test $failures -eq 0

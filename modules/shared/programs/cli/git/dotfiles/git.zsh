# source: https://stackoverflow.com/questions/5189560/how-do-i-squash-my-last-n-commits-together
function gsquash() {
  # Reset the current branch to the commit just before the last 12:
  git reset --hard "HEAD~$1"

  # HEAD@{1} is where the branch was just before the previous command.
  # This command sets the state of the index to be as it would just
  # after a merge from that commit:
  git merge --squash HEAD@{1}
}

function gundo() {
  # Undo last commit
  git reset --soft "HEAD~"
}


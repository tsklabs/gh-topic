#!/bin/bash

#
# INITIALIZE
#

__PROGRAM__=$(basename $0)
__COMMAND_NAME__=${__PROGRAM__%%.*}
__GH_EXTENSION_DIR__="$(dirname "$0")/../../"
__COMMANDS_DIR__="$(dirname "$0")"

#
# IMPORTS
#

source "${__GH_EXTENSION_DIR__}/source/extras/addons.sh"
source "${__COMMANDS_DIR__}/${__COMMAND_NAME__}.help"

#
# VARS
#

#
# LOGIC
#

main() {

  local reponame=$1
  local topics=$2

  local owner \
    query \
    mutation \
    default_loop_separator \
    repo_id \
    repo_full_name

  x:log "__COMMAND_NAME__[$__COMMAND_NAME__] __GH_EXTENSION_DIR__[$__GH_EXTENSION_DIR__] __COMMANDS_DIR__[$__COMMANDS_DIR__]"

  x:log "Getting owner from reponame[${reponame}]..."
  owner="$(echo ${reponame%%/*})"
  x:log "owner: ${owner}"

  if [[ "${owner}" == "${reponame}" ]]; then
    x:log "Setting default git user has owner..."
    owner="$(git config --global user.name)"
    x:check $?
    x:log "owner[${owner}] set as default"
  fi

  query='
    query repositoryIdFor($reponame: String!, $owner: String!) {
      repository(name: $reponame, owner: $owner) {
        id
      }
    }
  '

  mutation='
    mutation addTopicToRepoWithIdOwnedBy($repoId: String!, $topic: String!) {
      acceptTopicSuggestion(input: {repositoryId: $repoId,  name: $topic}) {
        topic {
          name
        }
      }
    }
  '

  repo_full_name="${owner}/${reponame}"

  x:log "Getting repo id using a graphql query..."
  repo_id=$(gh api graphql -F owner="${owner}" -F reponame="${reponame}" \
    -f query="${query}" \
    -q '.data.repository.id' 2>/dev/null)
  x:check $? "Repository[${repo_full_name}] not found. Unable to get its repository ID"
  x:log "repo_id: ${repo_id}"

  x:log "Adding topics[${topics}] to repo[${repo_full_name}..."

  default_loop_separator=$IFS
  IFS=","
  for rawtopic in $topics; do

    x:log "Trimming rawtopic[${rawtopic}]..."

    topic=$(echo $rawtopic | sed -e 's/^[[:space:]]*//')
    x:check $?
    x:log "topic[${topic}] trimmed."

    x:log "Adding topic[${topic}] to repo[${repo_full_name}] of id[${repo_id}] using a graphql mutation..."
    gh api graphql -F repoId="${repo_id}" -F topic="${topic}" \
      -f query="${mutation}" \
      --silent 2>/dev/null
    x:check $? "Fail to add topic[${topic}] to the repository[${repo_full_name}]"
    x:log "Topic[${topic}] added."

  done
  IFS=${default_loop_separator}

  x:success "Topics[$topics] added to repo[${repo_full_name}]"

}

#
# OPTIONS ARGS
#

if test $# -eq 0; then
  add:help
  exit 1
fi

while test $# -gt 0; do
  case "$1" in

  -h | --help)

    add:help
    exit 0
    ;;

  --debug)
    shift
    __VERBOSE__="true"
    ;;

  -r | --reponame)
    shift
    arg_reponame=$1
    shift
    ;;

  --names)
    shift
    arg_topics=$1
    shift
    ;;

  *)
    x:err "Option[$1] is not supported."
    add:help
    ;;
  esac
done

#
# REQUIREMENTS
#

[[ -z ${arg_reponame} ]] && x:err "option[--reponame] is required!"
[[ -z ${arg_topics} ]] && x:err "option[--names] is required!"

#
# EXEC
#

main "${arg_reponame}" "$arg_topics"

#!/bin/bash

#
# INITIALIZE
#

__PROGRAM__=$(basename $0)
__COMMAND_NAME__=${__PROGRAM__%%.*}
__GH_EXTENSION_DIR__="$(dirname "$0")/../../"
__COMMANDS_DIR__="$(dirname "$0")"
__CORE_DIR__="${__GH_EXTENSION_DIR__}/source/core"

#
# IMPORTS
#

source "${__GH_EXTENSION_DIR__}/source/extras/addons.sh"
source "${__COMMANDS_DIR__}/${__COMMAND_NAME__}.help"
source "${__CORE_DIR__}/topic.sh"

#
# VARS
#

#
# LOGIC
#

main() {

  local reponame=$1
  local topics=$2

  local owner

  local query \
    mutation \
    data

  local repo_id \
    repo_topics

  local default_loop_separator
  local repo_full_name

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
    query repositoryIdWithTopicsFor($reponame: String!, $owner: String!) {
      repository(name: $reponame, owner: $owner) {
        id
        topics: repositoryTopics(first: 100) {
          edges {
            node {
              topic {
                name
              }
            }
          }
        }
      }
    }
  '

  local template='{{ .data.repository.id }}:{{ range $idx, $element := .data.repository.topics.edges }}{{ if $idx }} {{end}}{{ $element.node.topic.name }}{{ end }}'

  mutation='
    mutation removeTopicToRepoWithIdOwnedBy($repoId: String!, $topic: String!) {
      declineTopicSuggestion(input: { repositoryId: $repoId, name: $topic, reason: NOT_RELEVANT }) {
        topic {
          name
        }
      }
    }
  '

  repo_full_name="${owner}/${reponame}"

  x:log "Getting repo id using a graphql query..."
  data=$(gh api graphql -F owner="${owner}" -F reponame="${reponame}" \
    -f query="${query}" \
    -t "$template" 2>/dev/null)
  x:check $? "Repository[${repo_full_name}] not found. Unable to get its repository ID"

  repo_id="$(echo $data | cut -d\: -f 1)"
  repo_topics="$(echo $data | cut -d\: -f 2)"
  x:log "repo_id: ${repo_id}\
  repo_topics: ${repo_topics}"

  x:log "Checking if the given topics[${topics}] are part of repository topics..."
  for rawtopic in $topics; do

    x:log "Trimming rawtopic[${rawtopic}]..."
    topic="$(echo $rawtopic | sed -e 's/^[[:space:]]*//')"

    if ! topic:contains "$topic" "${repo_topics}"; then
      x:err "Topic[$topic] not found on repository[${repo_full_name}]  — topics[${repo_topics}]"
    fi

  done

  x:log "Removing topics[${topics}] to repo[${repo_full_name}..."

  for rawtopic in $topics; do

    x:log "Trimming rawtopic[${rawtopic}]..."
    topic=$(echo $rawtopic | sed -e 's/^[[:space:]]*//')
    x:check $?
    x:log "topic[${topic}] trimmed."

    x:log "Removing topic[${topic}] to repo[${repo_full_name}] of id[${repo_id}] using a graphql mutation..."
    gh api graphql -F repoId="${repo_id}" -F topic="${topic}" \
      -f query="${mutation}" \
      --silent 2>/dev/null
    x:check $? "Fail to remove topic[${topic}] to the repository[${repo_full_name}]"
    x:log "Topic[${topic}] removed."

  done

  x:success "Topics[$topics] removed to repo[${repo_full_name}]"

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
    rm:help
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
    rm:help
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

space_separated_topics="${arg_topics//,/ }"

main "${arg_reponame}" "$space_separated_topics"

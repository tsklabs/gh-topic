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

  local input_reponame=$1
  local topics=$2

  local owner \
    reponame \
    query \
    mutation \
    data \
    repo_id \
    repo_topics \
    new_topics \
    merged_topics \
    repo_full_name

  x:log "__COMMAND_NAME__[$__COMMAND_NAME__] __GH_EXTENSION_DIR__[$__GH_EXTENSION_DIR__] __COMMANDS_DIR__[$__COMMANDS_DIR__]"

  x:log "Resolving owner/reponame from input_reponame[${input_reponame}]..."
  if [[ "${input_reponame}" == */* ]]; then
    owner="${input_reponame%%/*}"
    reponame="${input_reponame##*/}"
  else
    reponame="${input_reponame}"
    x:log "Setting default authenticated gh user as owner..."
    owner="$(gh api user -q '.login' 2>/dev/null)"
    x:check $? "Unable to detect default GitHub owner. Please provide --reponame as owner/repo."
    [[ -z "${owner}" ]] && x:err "Unable to detect default GitHub owner. Please provide --reponame as owner/repo."
    x:log "owner[${owner}] set as default"
  fi

  x:log "owner: ${owner}"
  x:log "reponame: ${reponame}"

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
    mutation updateTopicsForRepo($repoId: ID!, $names: [String!]!) {
      updateTopics(input: {repositoryId: $repoId, topicNames: $names}) {
        invalidTopicNames
        repository {
          repositoryTopics(first: 100) {
            nodes {
              topic {
                name
              }
            }
          }
        }
      }
    }
  '

  repo_full_name="${owner}/${reponame}"

  x:log "Getting repo id and current topics using a graphql query..."
  data=$(gh api graphql -F owner="${owner}" -F reponame="${reponame}" \
    -f query="${query}" \
    -t "$template" 2>/dev/null)
  x:check $? "Repository[${repo_full_name}] not found. Unable to get its repository ID"

  repo_id="$(echo "$data" | cut -d\: -f 1)"
  repo_topics="$(echo "$data" | cut -d\: -f 2)"
  x:log "repo_id: ${repo_id} repo_topics: ${repo_topics}"

  x:log "Parsing requested topics[${topics}]..."
  new_topics=$(topic:parse "$topics")
  x:log "new_topics: ${new_topics}"

  merged_topics=$(topic:union "${repo_topics}" "${new_topics}")
  x:log "merged_topics: ${merged_topics}"

  local -a name_args=()
  for topic in $merged_topics; do
    name_args+=(-F "names[]=${topic}")
  done

  x:log "Adding topics[${new_topics}] to repo[${repo_full_name}] of id[${repo_id}] using a graphql mutation..."
  gh api graphql "${name_args[@]}" -F repoId="${repo_id}" \
    -f query="${mutation}" \
    --silent 2>/dev/null
  x:check $? "Fail to add topics[${new_topics}] to the repository[${repo_full_name}]"

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

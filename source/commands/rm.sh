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

normalize:topics() {
  local raw_topics="$1"
  local rawtopic
  local topic
  local seen_topics=""

  for rawtopic in ${raw_topics//,/ }; do
    topic="$(echo "$rawtopic" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    [[ -z "${topic}" ]] && continue
    if [[ " ${seen_topics} " != *" ${topic} "* ]]; then
      echo "${topic}"
      seen_topics="${seen_topics} ${topic}"
    fi
  done
}

main() {

  local input_reponame=$1
  local topics=$2

  local owner
  local reponame

  local query \
    template \
    mutation \
    data

  local repo_id \
    repo_topics \
    repo_full_name \
    topic_names_graphql \
    topic \
    escaped_topic

  local -a requested_topics
  local -a existing_topics
  local -a resulting_topics

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

  template='{{ .data.repository.id }}{{ "\n" }}{{ range .data.repository.topics.edges }}{{ .node.topic.name }}{{ "\n" }}{{ end }}'

  repo_full_name="${owner}/${reponame}"

  x:log "Getting repo id and topics using a graphql query..."
  data=$(gh api graphql -F owner="${owner}" -F reponame="${reponame}" \
    -f query="${query}" \
    -t "${template}" 2>/dev/null)
  x:check $? "Repository[${repo_full_name}] not found. Unable to get its repository ID/topics"

  repo_id="$(echo "${data}" | head -n 1)"
  [[ -z "${repo_id}" ]] && x:err "Repository[${repo_full_name}] not found. Unable to get its repository ID"
  repo_topics="$(echo "${data}" | tail -n +2 | tr '\n' ',')"
  x:log "repo_id: ${repo_id} repo_topics: ${repo_topics}"

  mapfile -t requested_topics < <(normalize:topics "${topics}")
  [[ ${#requested_topics[@]} -eq 0 ]] && x:err "No valid topics provided in --names[${topics}]"

  mapfile -t existing_topics < <(normalize:topics "${repo_topics}")

  x:log "Checking if given topics[${topics}] are part of repository topics..."
  for topic in "${requested_topics[@]}"; do
    if [[ " ${existing_topics[*]} " != *" ${topic} "* ]]; then
      x:err "Topic[${topic}] not found on repository[${repo_full_name}] — topics[${existing_topics[*]}]"
    fi
  done

  resulting_topics=()
  for topic in "${existing_topics[@]}"; do
    if [[ " ${requested_topics[*]} " != *" ${topic} "* ]]; then
      resulting_topics+=("${topic}")
    fi
  done

  topic_names_graphql="["
  local first_topic=true
  for topic in "${resulting_topics[@]}"; do
    escaped_topic="${topic//\"/\\\"}"
    if [[ "${first_topic}" == "true" ]]; then
      first_topic=false
    else
      topic_names_graphql+=", "
    fi
    topic_names_graphql+="\"${escaped_topic}\""
  done
  topic_names_graphql+="]"

  mutation="
    mutation updateTopicsOnRepo {
      updateTopics(input: {repositoryId: \"${repo_id}\", topicNames: ${topic_names_graphql}}) {
        clientMutationId
      }
    }
  "

  x:log "Removing topics[${topics}] from repo[${repo_full_name}] using updateTopics..."
  gh api graphql \
    -f query="${mutation}" \
    --silent 2>/dev/null
  x:check $? "Fail to remove topics[${topics}] from repository[${repo_full_name}]"

  x:success "Topics[$topics] removed to repo[${repo_full_name}]"

}

#
# OPTIONS ARGS
#

if test $# -eq 0; then
  rm:help
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

main "${arg_reponame}" "${arg_topics}"

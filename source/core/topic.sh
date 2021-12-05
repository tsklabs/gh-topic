topic:contains() {
  local topic
  local topics
  local occurrence

  topic="$1"
  topics="$2"

  occurrence=$(echo $topics | tr ' ' '\n' | grep -cE "^${topic}$" 2>/dev/null)

  if [[ $occurrence -gt 0 ]]; then
    return 0
  else
    return 1
  fi

}

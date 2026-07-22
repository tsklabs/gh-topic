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

# topic:parse: splits a comma-separated topic list, trims whitespace and dedupes
# params
#   - raw comma-separated topic names (eg: "foo, bar,bar")
# stdout: space-separated, deduped topic list (eg: "foo bar")
topic:parse() {
  local raw="$1"
  local default_loop_separator=$IFS
  local rawtopic
  local topic
  local parsed=""

  IFS=","
  for rawtopic in $raw; do
    topic=$(echo "$rawtopic" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    [[ -z "$topic" ]] && continue
    if ! topic:contains "$topic" "$parsed"; then
      parsed="${parsed:+$parsed }${topic}"
    fi
  done
  IFS=$default_loop_separator

  echo "$parsed"
}

# topic:union: merges two space-separated topic lists, deduped
# params
#   - base space-separated topic list
#   - additional space-separated topic list
# stdout: space-separated, deduped union of both lists
topic:union() {
  local base="$1"
  local additional="$2"
  local result="$base"
  local topic

  for topic in $additional; do
    if ! topic:contains "$topic" "$result"; then
      result="${result:+$result }${topic}"
    fi
  done

  echo "$result"
}

# topic:difference: removes topics found in the second list from the first
# params
#   - base space-separated topic list
#   - space-separated topic list to remove
# stdout: space-separated topic list with removals applied
topic:difference() {
  local base="$1"
  local remove="$2"
  local result=""
  local topic

  for topic in $base; do
    if ! topic:contains "$topic" "$remove"; then
      result="${result:+$result }${topic}"
    fi
  done

  echo "$result"
}

set -l ctx7_key (security find-generic-password -a "$USER" -s context7-api-key -w 2>/dev/null)
if test -n "$ctx7_key"
    set -gx CONTEXT7_API_KEY $ctx7_key
end

set -l opencode_api_key (security find-generic-password -a "$USER" -s opencode-api-key -w 2>/dev/null)
if test -n "$opencode_api_key"
    set -gx OPENCODE_API_KEY "$opencode_api_key"
end

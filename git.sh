#!/bin/bash
changed=$(git status --porcelain | grep "^.[AMDR]" | wc -l)
staged=$(git status --porcelain | grep "^[AMDR]" | wc -l)
commits_behind=$(git rev-list HEAD..origin/$(git branch --show-current) 2>/dev/null | wc -l)
commits_ahead=$(git rev-list origin/$(git branch --show-current)..HEAD 2>/dev/null | wc -l)

echo "Changed files : $changed"
echo "Added files : $staged"
echo "Commited files : $commits_ahead"

if [ "$changed" -gt 0 ]; then
    echo -e "\033[0;31mChanged and waiting for add\033[0m"       # أحمر
elif [ "$staged" -gt 0 ]; then
    echo -e "\033[0;33mAdded and waiting for commit\033[0m"     # برتقالي / أصفر غامق
elif [ "$commits_ahead" -gt 0 ]; then
    echo -e "\033[0;34mCommited and waiting for push\033[0m"     # أزرق
else
    echo -e "\033[0;32mEverything up to date\033[0m"              # أخضر
fi
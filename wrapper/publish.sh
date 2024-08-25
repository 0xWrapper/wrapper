#!/bin/bash

 out=$(sui client publish --skip-dependency-verification --skip-fetch-latest-git-deps)
#out=$(sui client publish)

if [ $? -eq 0 ]; then
    echo "$out"
else
    echo "$out"
    echo "Error: sui client publish failed."
    exit 1
fi

package_id=$(echo "$out"| sed -n '/Published Objects/,/Version/ s/.*PackageID: //p' )

echo ""
echo "──────────────────────────────────────────────────────────────────────────────────────────────────────────────────"
echo ""

echo "PackageID:"
echo "$package_id"

echo ""
echo "──────────────────────────────────────────────────────────────────────────────────────────────────────────────────"
echo ""
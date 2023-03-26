echo "Running dbt build:"
echo ""
dbt build --profiles-dir .
echo "Running dbt source freshness:"
echo ""
dbt source freshness --profiles-dir .
echo "Generating dbt docs site:"
echo ""
dbt docs generate --profiles-dir .
echo ""
echo "Copying dbt artifcats to s3 for documentation hosting"
aws s3 cp --recursive --exclude="*" --include="*.json" --include="*.html" target/ s3://www.nhleltdocs.com
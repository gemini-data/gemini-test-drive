#!/bin/sh


echo ""
echo "This will teardown your Gemini Enterprise Cluster IRREVERSIBLY!"
echo ""

echo
read -r -p "Are you sure to continue? [y/N] " response
case "$response" in
    [yY][eE][sS]|[yY])
        break
        ;;
    *)
        echo "Alright, not going to touch anything but just exit."
        echo ""
        exit 1
        ;;
esac

echo "Ok, tearing down the cluster now..."

docker exec -it gemini-setup gectl cluster reset -c setup.yaml -vvvv

rm -f setup.yaml
rm -rf var

echo ""
echo "Cluster removed. We hope you enjoyed the Gemini Enterprise Test Drive. Please share any feedback at product@geminidata.com!"

DIR=$(ls -I)
for entry in $DIR; do
	mv $entry $(echo $entry | sed -e 's/.local//g')
done

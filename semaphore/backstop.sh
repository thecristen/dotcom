#/usr/bin/env bash
set -e

DOCKER_INTERNAL_IP="127.0.0.1"
echo "Replacing host.docker.internal with $DOCKER_INTERNAL_IP"
`sed -r -e "s/host.docker.internal/$DOCKER_INTERNAL_IP/" -i'' apps/site/test/backstop.json`
`sed -r -e "s/host.docker.internal/$DOCKER_INTERNAL_IP/" -i'' package.json`

sudo service docker start

npm run webpack:build

(mkdir -p bin && cd bin && curl -O http://repo1.maven.org/maven2/com/github/tomakehurst/wiremock-standalone/2.14.0/wiremock-standalone-2.14.0.jar)

npm run wiremock &

npm run server:mocked:nocompile 1>/dev/null 2>/dev/null &

until $(curl --output /dev/null --silent --head --fail http://localhost:8082/_health); do
  printf 'waiting for server...\n'
  sleep 5
done

cd apps/site/assets && npm install && cd -

set +e

docker run --rm -it --network host --mount type=bind,source="/home/runner/dotcom/apps/site/test",target=/src backstopjs/backstopjs:3.5.16 test "--_=test" "--h=false" "--help=false" "--v=false" "--version=false" "--i=false" "--moby=true" "--config=backstop.json" "--moby"

if [ $? -eq 0 ]
then
  echo "Backstop tests passed!"
  exit 0
else
  echo "Some tests failed."
  BRANCH=`git branch | grep \* | cut -d ' ' -f2`
  FILENAME="$BRANCH.tar.gz"
  tar -czvf $FILENAME apps/site/test/backstop_data
  aws s3 cp $FILENAME s3://mbta-semaphore/$FILENAME
  LINK=`aws s3 presign s3://mbta-semaphore/$FILENAME --expires-in 1800`
  echo "Backstop report located at $LINK, available for 30 minutes."
  exit 0
fi

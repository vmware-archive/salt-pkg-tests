sudo docker build . -t dl-pkg-test
sudo docker run -it dl-pkg-test /bin/bash -c "cd /testing/; git pull; python3.6 /testing/test_download/download.py -b 2017.7 -v 2017.7.4"

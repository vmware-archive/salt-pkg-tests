sudo docker build . -t dl-pkg-test:alpine
sudo docker run -it dl-pkg-test:alpine python3.6 /testing/download.py -b 2017.7 -v 2017.7.6

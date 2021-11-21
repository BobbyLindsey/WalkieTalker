
# Update and Upgrade
sudo apt update
sudo apt upgrade -y

# Install Git
sudo apt install -y git

# Enable SPI in Raspi-Config


# Install the ReSpeaker 2-Mic HAT 
git clone https://github.com/respeaker/seeed-voicecard
cd seeed-voicecard
sudo ./install.sh 2mic

# Install TalkiePi Pre-Reqs
sudo apt install -y libopenal-dev libopus-dev golang

# Setup Golang
mkdir -p ${HOME}/go/src
mkdir -p ${HOME}/go/bin
GOPATH=${HOME}/go > /etc/profile
GOBIN=${HOME}/go/bin > /etc/profile
PATH=${PATH}:${GOPATH}/bin > /etc/profile

# Install TalkiePi
cd ${GOPATH}/src
go get periph.io/x/periph
go get github.com/dchote/gopus
go get github.com/BobbyLindsey/talkiepi
go build -o ${GOPATH}/bin/talkiepi ${GOPATH}/src/github.com/BobbyLindsey/talkiepi/cmd/talkiepi/main.go

# Setup Service
sudo cp /home/pi/go/src/github.com/BobbyLindsey/talkiepi/conf/systemd/mumble.service /etc/systemd/system/mumble.service
sudo systemctl enable mumble.service
sudo systemctl daemon-reload
sudo systemctl restart mumble.service


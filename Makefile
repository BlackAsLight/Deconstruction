DIRECTORY := $(shell cat info.json | jq '.name')_$(shell cat info.json | jq '.version')
NAME := $(DIRECTORY).zip

all:
	rm -rf $(NAME)
	mkdir $(DIRECTORY)
	cp *.lua $(DIRECTORY)
	cp *.json $(DIRECTORY)
	cp changelog.txt $(DIRECTORY)
	cp LICENSE $(DIRECTORY)
	zip -9qr $(NAME) ./$(DIRECTORY)
	rm -rf $(DIRECTORY)

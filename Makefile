NAME := $(shell cat info.json | jq '.name')_$(shell cat info.json | jq '.version').zip

all:
	rm -rf $(NAME)
	zip -9qr $(NAME) . -i *.lua *.json LICENSE

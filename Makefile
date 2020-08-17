NAME = uart-db
VERSION = v1.4
BUILD = $(NAME)-build

release:
	(cd client; make)
	(cd doc; make)
	mkdir -p $(BUILD)
	mkdir -p $(BUILD)/client
	mkdir -p $(BUILD)/module
	cp readme.md $(BUILD)
	cp client/open-ports $(BUILD)
	cp -r client/src $(BUILD)/client
	cp -r client/build $(BUILD)/client
	cp -r module/design $(BUILD)/module
	cp -r module/testbench $(BUILD)/module
	tar czf $(NAME)-$(VERSION).tar.gz $(BUILD)/*
	rm -r $(BUILD)

clean:
	(cd client; make clean)
	(cd doc; make remove)
	rm -f $(NAME)-$(VERSION).tar.gz

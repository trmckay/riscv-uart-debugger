NAME = uart-db
VERSION = v1.0
BUILD = $(NAME)-build
CLIENT = client/build
DOC = doc/pdf
MODULE = module/design

all:
	(cd doc; make)
	(cd client; make)
	mkdir -p $(BUILD)
	mkdir -p $(BUILD)/client
	mkdir -p $(BUILD)/doc
	mkdir -p $(BUILD)/module
	cp $(CLIENT)/* $(BUILD)/client
	cp $(DOC)/* $(BUILD)/doc
	cp $(MODULE)/* $(BUILD)/module
	(cd client; make clean)
	(cd doc; make remove)
	@echo -e "\nMake successful!"

release:
	make all
	cp -r client/src $(BUILD)
	tar czf $(NAME)-$(VERSION).tar.gz $(BUILD)/*
	rm -r $(BUILD)

install:
	(cd client; make install)
	@echo "Client installed successfully! Please make sure your MCU is properly set up."
	@echo "See documentation for instructions."

clean:
	rm -rf $(BUILD)
	(cd client; make clean)
	(cd doc; make remove)
	rm -f $(NAME)-$(VERSION).tar.gz

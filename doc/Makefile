TOOL = pdflatex
DIR = tex
TEX = protocol.tex
TARGET = pdf

all:
	(cd $(DIR); $(TOOL) $(TEX))
	mkdir -p $(TARGET)
	mv tex/*.pdf pdf
clean:
	(rm *.log; cd tex; rm *.aux *.out *.log)

remove:
	(rm -r pdf *.log; cd tex; rm *.aux *.out *.log)

TOOL = pdflatex
DIR = tex
TEX = protocol.tex
TARGET = pdf

all:
	(cd $(DIR); $(TOOL) $(TEX); $(TOOL) $(TEX))
	mkdir -p $(TARGET)
	mv tex/*.pdf pdf
clean:
	(rm -f *.log; cd tex; rm -f *.aux *.out *.log)

remove:
	(rm -rf pdf *.log; cd tex; rm -f *.aux *.out *.log)

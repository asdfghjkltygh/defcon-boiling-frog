.PHONY: install run attack attack-fast clean

install:
	pip install -r requirements.txt

run:
	python boiling_frog_exploit.py

attack:
	python boiling_frog_exploit.py --attack

attack-fast:
	python boiling_frog_exploit.py --attack --fast

clean:
	rm -f assets/plot*.png assets/table*.csv

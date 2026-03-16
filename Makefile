.PHONY: install run attack clean

install:
	pip install -r requirements.txt

run:
	python boiling_frog_exploit.py

attack:
	python boiling_frog_exploit.py --demo

clean:
	rm -f assets/plot*.png assets/table*.csv

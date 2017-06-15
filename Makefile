CC=gcc
CPP=g++
LEX=flex
SNTX=bison

lfile=mklab.l
yfile=mklab.yy

all:	
	$(SNTX) -d $(yfile);
	$(CPP) -std=c++11 -c mklab.tab.cc;
	$(LEX)  $(lfile);
	$(CC) -c lex.yy.c;
	$(CPP) -std=c++11 lex.yy.o mklab.tab.o -o mklab -ll ;
	rm -r lex.yy.*  mklab.tab.*;
	clear;
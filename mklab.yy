%{
// mozliwe zwroty: $tokeny oraz [ ] ( ) { } = + - * / ? & | ! > < ; #
#ifndef ASSERT_ON
	#define ASSERT_ON false
#endif

using namespace std;
#include <string>
#include <stdio.h>
#include <string.h>
#include <iostream>
#include <fstream>
#include <stack>
#include <map>
#include <vector>
#include <sstream>
#define INFILE_ERROR 1
#define OUTFILE_ERROR 2
extern "C" int yylex();
extern "C" int yyerror(const char *msg, ...);
extern ifstream yyin;
extern ofstream yyout;

vector<int> tempArraySize;
static bool FAIL=false;
stringstream code;
struct codes
{
	string code;
	string label;
	string label2; // label na skok wyjsciowy w petli
};
stack<codes> codesStack;
class variable;
static int tempVarSize=0;
static int labelSize=0;
static int stringSize=0;
map<string,variable> Symbols;
map<string,bool> functions;
map<string,vector<int>> arrays;
map<string,vector<std::string>> arraySize;
map<string,vector<std::string>> structs;
map<string,vector<std::string>> structsTypes;
vector<std::string> structTypes;
vector<std::string> structTypesTypes;
class variable
{
public:
	variable() {}
	variable(string input, string inputType) :type(inputType), size(1)
	{
		input = input + ",";
		int start = 0, end;
		while (start<input.length())
		{
			end = input.substr(start).find(",");
			var.push_back(input.substr(start, end));
			start += end + 1;
		}
	}
	string getType() { return type; }
	int getSize() { return size; }
	string getVar(int pos) { if (pos < var.size()) return var[pos]; return "NULL"; }
	string getVar() { return var[0]; }
	string getVarType() { return type; }
private:
	vector<std::string> var;
	string type;
	int size;
};

class expression;
expression *expression_pointer1=NULL, *expression_pointer2=NULL;
stack<expression*> Stack;
class expression
{
public:
	expression(string input, string inputType): val(input), valType(inputType) {};
	friend ostream& operator<<(ostream& os, expression& input)
	{
		return os << input.print();
	}
	string getVal() {return val;}
	string getValType() {return valType;}
private: 
	string print()
	{
		return "(" + valType + ")" + val;
	}
	string val;
	string valType;
};
void assert(string msg) {if (ASSERT_ON) cout<<msg<<"\n";}
void assert( void (* foo)()) {if (ASSERT_ON) foo();}
void create_struct(string Struct, string name)
{
	if (structs.find(Struct) == structs.end())
		{
			cout<<"Struct "<<Struct<<" isn't declarated\n";
			FAIL=true;
		}
		else
		{
			vector<std::string> temp=structs.at(Struct);
			vector<std::string> tempTypes=structsTypes.at(Struct);
			for (int i=0; i<temp.size(); i++)
			{
				string temp_name=name+string(".");
				string temp_type=tempTypes[i];
				assert(temp_name+temp[i]+string(" ")+temp_type);
				if (temp_type!="float" && temp_type!="word")
				{
					if (temp_type=="wordA")
					{
						int t=1; for (auto x: arrays[temp[i]] ) t*=x;
						Symbols[name+temp[i]] = variable(to_string(t),"wordA"); 
						arrays[name+temp[i]]=arrays[temp[i]];
					}
					else if (temp_type=="floatA")
					{
						int t=1; for (auto x: arrays[temp[i]] ) t*=x;
						Symbols[name+temp[i]] = variable(to_string(t),"floatA"); 
						arrays[name+temp[i]]=arrays[temp[i]];
					}
					else
						create_struct(temp_type,temp_name+temp[i]);
				}
				else
				{
					Symbols[temp_name+temp[i]] = variable(temp_name+temp[i],tempTypes[i]);
				}
			}
		}
}
void showStack()
{
	stack<expression*> Stack2;
	while (!Stack.empty())
	{
		Stack2.push(Stack.top());
		cout <<  ".Stack" << to_string(Stack.size()-1) << "=" << *Stack2.top() << "\n";
		Stack.pop();
	}
	while (!Stack2.empty())
	{
		Stack.push(Stack2.top());
		Stack2.pop();
	}
}
void stack_operator(char operation)
{
	assert(&showStack);
	expression_pointer1 = Stack.top();
	Stack.pop();
	expression_pointer2 = Stack.top();
	Stack.pop();
	
	string val1=expression_pointer2->getVal();
	string val1Type=expression_pointer2->getValType();
	delete expression_pointer2;
	string val2=expression_pointer1->getVal();
	string val2Type=expression_pointer1->getValType();
	delete expression_pointer1;
	
	double v1=0,v2=0;
	if ("NAME"==val1Type)
		if (Symbols.find(val1) == Symbols.end()) 
		{
			cout << "Symblol \"" << val1 << "\" not found!\n";
			FAIL=true;
			return;
		}
		else 
		{
			if ("word"==Symbols.at(val1).getVarType())
			{
				//v1 = stoi(Symbols.at(val1).getVar());
				code<<"\tlw\t$t1,\t"<<val1<<"\n";
			}
			else
			{
				code<<"\tl.s\t$f1,\t"<<val1<<"\n";
				//v1 = stod(Symbols.at(val1).getVar());
			}
			val1Type=Symbols.at(val1).getVarType();
		}
	else
		if ("word"==val1Type)
		{
			v1 = stoi(val1);
			code<<"\tli\t$t1,\t"<<(int)v1<<"\n";
		}
		else
		{
			v1 = stod(val1);
			code<<"\tl.s\t$f1,\t"<<v1<<"\n";
		}
			
	if ("NAME"==val2Type)
		if (Symbols.find(val2) == Symbols.end()) 
		{
			cout << "Symblol \"" << val2 << "\" not found!\n";
			FAIL=true;
			return;
		}
		else 
		{
			if ("word"==Symbols.at(val2).getVarType())
			{
				code<<"\tlw\t$t2,\t"<<val2<<"\n";
				//v2 = stoi(Symbols.at(val2).getVar());
			}
			else
			{
				code<<"\tl.s\t$f2,\t"<<val2<<"\n";
				//v2 = stod(Symbols.at(val2).getVar());
			}
			val2Type=Symbols.at(val2).getVarType();
		}
	else
		if ("word"==val2Type)
		{
			v2 = stoi(val2);
			code<<"\tli\t$t2,\t"<<(int)v2<<"\n";
		}
		else
		{
			v2 = stod(val2);
			code<<"\tl.s\t$f2,\t"<<v2<<"\n";
		}
	
	double result = 0;
	switch (operation)
	{
	case '&':
		result = (bool)v1 & (bool)v2;
		if ("word"==val2Type)
			code<<"\tand"<<"\t$t0,\t$t1,\t$t2\n";
		else
			code<<"\tand"<<"\t$f0,\t$f1,\t$f2\n";
		break;
	case '|':
		result = (bool)v1 | (bool)v2;
		if ("word"==val2Type)
			code<<"\tor"<<"\t$t0,\t$t1,\t$t2\n";
		else
			code<<"\tor"<<"\t$f0,\t$f1,\t$f2\n";
		break;
	case '?':
		result = v1 == v2;
		if ("word"==val2Type)
			code<<"\tbeq\t$t1,\t$t2,\tl"<<labelSize++<<"\n";
		else
			code<<"\tbeq\t$f1,\t$f2,\tl"<<labelSize++<<"\n";
		code<<"\tli\t$t0,\t0\n";
		if ("word"==val2Type)
		{
			code<<"\tbne\t$t1,\t$t2,\tl"<<labelSize++<<"\n";
			code<<"l"<<labelSize-2<<":\n\tli\t$t0,\t1\n";	
		}
		else
		{
			code<<"\tbne\t$f1,\t$f2,\tl"<<labelSize++<<"\n";
			code<<"l"<<labelSize-2<<":\n\tli\t$f0,\t1\n";
		}
		code<<"l"<<labelSize-1<<":\n";
		break;
	case '<':
		result = v1 < v2;
		if ("word"==val2Type)
			code<<"\tslt"<<"\t$t0,\t$t1,\t$t2\n";
		else
			code<<"\tslt"<<"\t$f0,\t$f1,\t$f2\n";
		break;
	case '>':
		result = v1 > v2;
		if ("word"==val2Type)
			code<<"\tslt"<<"\t$t0,\t$t2,\t$t1\n";
		else
			code<<"\tslt"<<"\t$f0,\t$f2,\t$f1\n";
		break;
	case '+':
		result = v1 + v2;
		if ("word"==val2Type)
			code<<"\tadd"<<"\t$t0,\t$t1,\t$t2\n";
		else
			code<<"\tadd.s"<<"\t$f0,\t$f1,\t$f2\n";
		break;
	case '-':
		result = v1 - v2;
		if ("word"==val2Type)
			code<<"\tsub"<<"\t$t0,\t$t1,\t$t2\n";
		else
			code<<"\tsub.s"<<"\t$f0,\t$f1,\t$f2\n";
		break;
	case '*':
		result = v1 * v2;
		if ("word"==val2Type)
			code<<"\tmul"<<"\t$t0,\t$t1,\t$t2\n";
		else
			code<<"\tmul.s"<<"\t$f0,\t$f1,\t$f2\n";
		break;
	case '/':
		result = v1 / v2;
		if ("word"==val2Type)
			code<<"\tdiv"<<"\t$t0,\t$t1,\t$t2\n";
		else
			code<<"\tdiv.s"<<"\t$f0,\t$f1,\t$f2\n";
		break;
	}
	
	
	if ("word"==val2Type)
	{
		Stack.push(new expression(".iStack"+to_string(tempVarSize),"NAME"));
		Symbols[".iStack"+to_string(tempVarSize)]= variable(to_string(result), "word");
		code<<"\tsw\t$t0,\t.iStack"<<tempVarSize<<"\n\n";	
	}
	else
	{
		Stack.push(new expression(".fStack"+to_string(tempVarSize),"NAME"));
		Symbols[".fStack"+to_string(tempVarSize)]= variable(to_string(result), "float");
		code<<"\ts.s\t$f0,\t.fStack"<<tempVarSize<<"\n\n";	
	}
	tempVarSize++;
	assert("Result= "+to_string(result)+"\ntempVarSize= "+to_string(tempVarSize)+"\n");
}
void stack_single_operator(char operation)
{
	assert(&showStack);
	expression_pointer1 = Stack.top();
	Stack.pop();
	
	string val1=expression_pointer1->getVal();
	string val1Type=expression_pointer1->getValType();
	delete expression_pointer1;
	
	double v1=0;
	if ("NAME"==val1Type)
		if (Symbols.find(val1) == Symbols.end()) 
		{
			cout << "Symblol \"" << val1 << "\" not found!\n";
			FAIL=true;
			return;
		}
		else 
		{
			if ("word"==Symbols.at(val1).getVarType())
			{
			code<<"\tlw\t$t1,\t"<<val1<<"\n";
				v1 = stoi(Symbols.at(val1).getVar());
				}
			else
			{
			code<<"\tl.s\t$f1,\t"<<val1<<"\n";
				v1 = stod(Symbols.at(val1).getVar());
				}
			val1Type=Symbols.at(val1).getVarType();
		}
	else
		if ("word"==val1Type)
		{
			v1 = stoi(val1);
			code<<"\tli\t$t1,\t"<<(int)v1<<"\n";
		}
		else
		{
			v1 = stod(val1);
			code<<"\tl.s\t$f1,\t"<<v1<<"\n";
		}
	
	double result = 0;
	switch (operation)
	{
	case '!':
		result = !v1;
		if ("word"==val1Type)
		{
			code<<"\tli\t$t2,\t0\n";
			code<<"\tbeq\t$t1,\t$t2,\tl"<<labelSize++<<"\n";
			code<<"\tli\t$t0,\t0\n";
			code<<"\tbne\t$t1,\t$t2,\tl"<<labelSize++<<"\n";
			code<<"l"<<labelSize-2<<":\n\tli\t$t0,\t1\n";
			code<<"l"<<labelSize-1<<":\n";
		}
		else
		{
			code<<"\tl.s\t$f2,\t0\n";
			code<<"\tbeq\t$f1,\t$f2,\tl"<<labelSize++<<"\n";
			code<<"\tl.s\t$f0,\t0\n";
			code<<"\tbne\t$t1,\t$t2,\tl"<<labelSize++<<"\n";
			code<<"l"<<labelSize-2<<":\n\tl.s\t$f0,\t1\n";
			code<<"l"<<labelSize-1<<":\n";
		}
		break;
	}
		
	
	if ("word"==val1Type)
	{
		Stack.push(new expression(".iStack"+to_string(tempVarSize),"NAME"));
		Symbols[".iStack"+to_string(tempVarSize)]= variable(to_string(result), "word");
		code<<"\tsw\t$t0,\t.iStack"<<tempVarSize<<"\n\n";
	}
	else
	{
		Stack.push(new expression(".fStack"+to_string(tempVarSize),"NAME"));
		Symbols[".fStack"+to_string(tempVarSize)]= variable(to_string(result), "float");
		code<<"\ts.s\t$f0,\t.fStack"<<tempVarSize<<"\n\n";
	}
	tempVarSize++;
	assert("Result= "+to_string(result)+"\ntempVarSize= "+to_string(tempVarSize)+"\n");
}
string saveSymbols()
{
	stringstream out;
	out << ".data" <<endl;
	for(map<string,variable>::iterator it = Symbols.begin(); it != Symbols.end(); it++)
		if (Symbols.at(it->first).getVarType()=="asciiz")
			out<<"\t"<<it->first<<":\t."<<Symbols.at(it->first).getVarType()<<"\t"<<Symbols.at(it->first).getVar()<<"\n";
		else if (Symbols.at(it->first).getVarType()=="wordA")
			out<<"\t"<<it->first<<":\t."<<"word"<<"\t0:"<<Symbols.at(it->first).getVar()<<"\n";
		else if (Symbols.at(it->first).getVarType()=="floatA")
			out<<"\t"<<it->first<<":\t."<<"float"<<"\t0:"<<Symbols.at(it->first).getVar()<<"\n";
		else
			out<<"\t"<<it->first<<":\t."<<Symbols.at(it->first).getVarType()<<"\t0\n";
	ofstream symbols("symbols.txt");
	if(symbols.is_open())   
    {
        symbols<<out.str();
		symbols.close();
    }
    else 
    {
        cout<<"Symbols.txt error";
    }
	return out.str();
}

int vectorMaxShift(string name, int index)
{
	vector<int> vec=arrays[name];
	int t=1;	
	for (int i=0; i<index; i++)
		t*=vec[i];
	return t;
}

%}
%union
{
	char* text;
	int ival;
	double dval;
};
%token <text> TEXT
%token <text> NAME
%token <ival> IVAL
%token <dval> DVAL
%token INT DOU STR ALO IFF ELS FOR WHI FUN OUT INN STU
%left '[' ']' '(' ')' '{' '}' '=' '+' '-' '*' '/' '?' '&' '|' '!' '>' '<' ';' '#'
%start begin
%%

testtest :expP3|expP3 array;

PRINT	:TEXT	{	
					Symbols[string(".String")+to_string(stringSize++)] = variable($1,"asciiz"); 
					code<<"\tli\t$v0,\t4\n"; 
					code<<"\tla\t$a0,\t.String"<<stringSize-1<<"\n";
					code<<"\tsyscall\n\n";
				} 
		|testtest{
					expression_pointer1 = Stack.top();
					if ("NAME"==expression_pointer1->getValType())
						if (Symbols.find(expression_pointer1->getVal()) == Symbols.end()) 
						{
							cout << "Symblol \"" << expression_pointer1->getVal() << "\" not found!\n";
							FAIL=true;
						}
						else 
						{
							if (Symbols.find(expression_pointer1->getVal()) == Symbols.end()) 
							{
								cout << "Symblol \"" << expression_pointer1->getVal() << "\" not declarated!\n";
								FAIL=true;
							}
							else
							{
								variable temp=Symbols.at(expression_pointer1->getVal());
								if ("word"==temp.getType())
								{
									code<<"\tli\t$v0,\t1\n";
									code<<"\tlw\t$a0,\t"<<expression_pointer1->getVal()<<"\n";
								}
								else
								{
									if ("float"==temp.getType())
									{
										code<<"\tli\t$v0,\t2\n";
										code<<"\tl.s\t$f12,\t"<<expression_pointer1->getVal()<<"\n";
									}
									else 
									if ("wordA"==temp.getType())
									{
										if (arrays.find(expression_pointer1->getVal()) == arrays.end()) 
										{
											cout << "Symblol \"" << expression_pointer1->getVal() << "\" is not array!\n";
											FAIL=true;
										}
										else
										{
											int shift=0;
											int sum=0;
											int i=0;
											for (auto j:tempArraySize)
												{sum+=j*vectorMaxShift(expression_pointer1->getVal(), i++);assert(to_string(sum)+" ");}
											if (sum>=stoi(Symbols[expression_pointer1->getVal()].getVar()))
												{assert(to_string(sum)+" "+Symbols[expression_pointer1->getVal()].getVar());
												cout<<"Index out of bound\n";FAIL=true;}
											code<<"\tli\t$t7,\t"<<sum*4<<"\n";
											code<<"\tla\t$t1,\t"<<expression_pointer1->getVal()<<"\n";
											code<<"\tadd\t$t1,\t$t1,\t$t7\n";
											code<<"\tli\t$v0,\t1\n";
											code<<"\tlw\t$a0,\t($t1)\n";
											tempArraySize.clear();
										}
									}
									else
									if ("floatA"==temp.getType())
									{
										if (arrays.find(expression_pointer1->getVal()) == arrays.end()) 
										{
											cout << "Symblol \"" << expression_pointer1->getVal() << "\" is not array!\n";
											FAIL=true;
										}
										else
										{
											int shift=0;
											int sum=0;
											int i=0;
											for (auto j:tempArraySize)
												{sum+=j*vectorMaxShift(expression_pointer1->getVal(), i++);assert(to_string(sum)+" ");}
											if (sum>=stoi(Symbols[expression_pointer1->getVal()].getVar()))
												{assert(to_string(sum)+" "+Symbols[expression_pointer1->getVal()].getVar());
												cout<<"Index out of bound\n";FAIL=true;}
											code<<"\tli\t$t7,\t"<<sum*4<<"\n";
											code<<"\tla\t$t1,\t"<<expression_pointer1->getVal()<<"\n";
											code<<"\tadd\t$t1,\t$t1,\t$t7\n";
											code<<"\tli\t$v0,\t2\n";
											code<<"\tl.s\t$f12,\t($t1)\n";
											tempArraySize.clear();
										}
									}
									else
									{
											code<<"\tli\t$v0,\t4\n"; 
											code<<"\tla\t$a0,\t"<<expression_pointer1->getVal()<<"\n";
									}
								}
							}
						}
					else
						if ("word"==expression_pointer1->getValType())
						{
							code<<"\tli\t$v0,\t1\n";
							code<<"\tli\t$a0,\t"<<stoi(expression_pointer1->getVal())<<"\n";
						}
						else
						{
							code<<"\tli\t$v0,\t2\n";
							code<<"\tli\t$f12,\t"<<expression_pointer1->getVal()<<"\n";
						}
					Stack.pop();
					delete expression_pointer1;
					code<<"\tsyscall\n\n";
		}
		|PRINT PRINT
		;

begin	:begin 	fun	';'
		|		fun	';'
		;

array2 	:'[' expP3 ']' {
								expression_pointer1 = Stack.top();
								if ("NAME"==expression_pointer1->getValType())
									if (Symbols.find(expression_pointer1->getVal()) == Symbols.end()) 
									{
										cout << "Symblol \"" << expression_pointer1->getVal() << "\" not found!\n";
										FAIL=true;
									}
									else 
									{
										variable temp=Symbols.at(expression_pointer1->getVal());
										tempArraySize.push_back(stoi(temp.getVar()));
									}
								else
									tempArraySize.push_back(stoi(expression_pointer1->getVal()));
								Stack.pop();
								delete expression_pointer1;
							}
		|;
array	:'[' expP3 ']' array2 {
								expression_pointer1 = Stack.top();
								if ("NAME"==expression_pointer1->getValType())
									if (Symbols.find(expression_pointer1->getVal()) == Symbols.end()) 
									{
										cout << "Symblol \"" << expression_pointer1->getVal() << "\" not found!\n";
										FAIL=true;
									}
									else 
									{
										variable temp=Symbols.at(expression_pointer1->getVal());
										tempArraySize.push_back(stoi(temp.getVar()));
									}
								else
									tempArraySize.push_back(stoi(expression_pointer1->getVal()));
								Stack.pop();
								delete expression_pointer1;
							}
		;
		
fun		:INT NAME			{if (string($2).find(".") != std::string::npos) {cout<<"Var name cant contain '.' sign.\n"; FAIL=true;} 
							else {Symbols[$2] = variable("0","word");} }
		|DOU NAME			{if (string($2).find(".") != std::string::npos) {cout<<"Var name cant contain '.' sign.\n"; FAIL=true;} 
							else {Symbols[$2] = variable("0","float");} }
		|STR NAME TEXT		{if (string($2).find(".") != std::string::npos) {cout<<"Var name cant contain '.' sign.\n"; FAIL=true;} 
							else {Symbols[$2] = variable($3,"asciiz");} }
		|INT NAME array {if (string($2).find(".") != std::string::npos) {cout<<"Var name cant contain '.' sign.\n"; FAIL=true;} 
							else 
							{ 
								int t=1; for (auto i:tempArraySize) t*=i;
								assert(to_string(t)+string(" array int")); 
								Symbols[$2] = variable(to_string(t),"wordA");  
								arrays[$2]=tempArraySize;
							}
							tempArraySize.clear();
						}
		
		|DOU NAME array {if (string($2).find(".") != std::string::npos) {cout<<"Var name cant contain '.' sign.\n"; FAIL=true;} 
							else 
							{ 
								int t=1; for (auto i:tempArraySize) t*=i;
								assert(to_string(t)+string(" array dou")); 
								Symbols[$2] = variable(to_string(t),"floatA");  
								arrays[$2]=tempArraySize;
							}
							tempArraySize.clear();
						} 
							
		|OUT PRINT
		|NAME INN  	{
						if (Symbols.find($1) == Symbols.end()) 
						{
							cout << "Symblol \"" << $1 << "\" not found!\n";
							FAIL=true;
						}
						else
						{
							variable temp=Symbols.at($1);
							if ("float"==temp.getType())
							{
								code<<"\tli\t$v0,\t6\n";
								code<<"\tsyscall\n\n";
								code<<"\ts.s\t$f0,\t"<<$1<<"\n";
							}
							else
							if (("word"==temp.getType()))
							{
								code<<"\tli\t$v0,\t5\n"; 
								code<<"\tsyscall\n\n";
								code<<"\tsw\t$v0,\t"<<$1<<"\n";
							}
							else
							{
								cout << "Symblol \"" << $1 << "\" isn't int or dou!\n";
								FAIL=true;
							}
						}						
					}
		|NAME array INN {
						if (Symbols.find($1) == Symbols.end()) 
						{
							cout << "Symblol \"" << $1 << "\" not found!\n";
							FAIL=true;
						}
						else
						{
							variable temp=Symbols.at($1);
							if ("wordA"==temp.getType())
							{
									if (arrays.find($1) == arrays.end()) 
										{
											cout << "Symblol \"" << $1 << "\" is not array!\n";
											FAIL=true;
										}
										else
										{
											int shift=0;
											int sum=0;
											int i=0;
											for (auto j:tempArraySize)
												{sum+=j*vectorMaxShift($1, i++);assert(to_string(sum)+" ");}
											if (sum>=stoi(Symbols[$1].getVar()))
												{assert(to_string(sum)+" "+Symbols[$1].getVar());
												cout<<"Index out of bound\n";FAIL=true;}
											code<<"\tli\t$v0,\t5\n"; 
											code<<"\tsyscall\n\n";
											code<<"\tli\t$t7,\t"<<sum*4<<"\n";
											code<<"\tla\t$t1,\t"<<$1<<"\n";
											code<<"\tadd\t$t1,\t$t1,\t$t7\n";
											code<<"\tsw\t$v0,\t($t1)\n";
											tempArraySize.clear();
										}
							}
							
							if ("floatA"==temp.getType())
							{
									if (arrays.find($1) == arrays.end()) 
										{
											cout << "Symblol \"" << $1 << "\" is not array!\n";
											FAIL=true;
										}
										else
										{
											int shift=0;
											int sum=0;
											int i=0;
											for (auto j:tempArraySize)
												{sum+=j*vectorMaxShift($1, i++);assert(to_string(sum)+" ");}
											if (sum>=stoi(Symbols[$1].getVar()))
												{assert(to_string(sum)+" "+Symbols[$1].getVar());
												cout<<"Index out of bound\n";FAIL=true;}
											code<<"\tli\t$v0,\t6\n"; 
											code<<"\tsyscall\n\n";
											code<<"\tli\t$t7,\t"<<sum*4<<"\n";
											code<<"\tla\t$t1,\t"<<$1<<"\n";
											code<<"\tadd\t$t1,\t$t1,\t$t7\n";
											code<<"\ts.s\t$f0,\t($t1)\n";
											tempArraySize.clear();
										}
							}
						}						
					}
		|NAME  '=' expP3
		{
			expression_pointer1 = Stack.top();
			if ("NAME"==expression_pointer1->getValType())
				if (Symbols.find(expression_pointer1->getVal()) == Symbols.end()) 
				{
					cout << "Symblol \"" << expression_pointer1->getVal() << "\" not found!\n";
					FAIL=true;
				}
				else 
				{
					if (Symbols.find($1) == Symbols.end()) 
					{
						cout << "Symblol \"" << $1 << "\" not declarated!\n";
						FAIL=true;
					}
					else
					{
						variable temp=Symbols.at(expression_pointer1->getVal());
						if ("word"==temp.getType())
							code<<"\tlw\t$t0,\t"<<expression_pointer1->getVal()<<"\n";
						else
							code<<"\tl.s\t$f0,\t"<<expression_pointer1->getVal()<<"\n";
					}
				}
			else
				if ("word"==expression_pointer1->getValType())
				{
					code<<"\tli\t$t0,\t"<<stoi(expression_pointer1->getVal())<<"\n";
				}
				else
				{
					code<<"\tl.s\t$f0,\t"<<expression_pointer1->getVal()<<"\n";
				}
			Stack.pop();
			delete expression_pointer1;
			if (Symbols.find($1) == Symbols.end()) 
			{
				cout << "Symblol \"" << $1 << "\" not found!\n";
				FAIL=true;
			}
			else
			{
				variable temp2=Symbols.at($1);
				if ("word"==temp2.getType())
					code<<"\tsw\t$t0,\t"<<$1<<"\n\n";
				else
					code<<"\ts.s\t$f0,\t"<<$1<<"\n\n";
			}
		}
		|NAME array  '=' expP3
		{
			expression_pointer1 = Stack.top();
			if ("NAME"==expression_pointer1->getValType())
				if (Symbols.find(expression_pointer1->getVal()) == Symbols.end()) 
				{
					cout << "Symblol \"" << expression_pointer1->getVal() << "\" not found!\n";
					FAIL=true;
				}
				else 
				{
					if (Symbols.find($1) == Symbols.end()) 
					{
						cout << "Symblol \"" << $1 << "\" not declarated!\n";
						FAIL=true;
					}
					else
					{
						variable temp=Symbols.at(expression_pointer1->getVal());
									if ("wordA"==temp.getType())
									{
										if (arrays.find(expression_pointer1->getVal()) == arrays.end()) 
										{
											cout << "Symblol \"" << expression_pointer1->getVal() << "\" is not array!\n";
											FAIL=true;
										}
										else
										{
											int shift=0;
											int sum=0;
											int i=0;
											for (auto j:tempArraySize)
												{sum+=j*vectorMaxShift(expression_pointer1->getVal(), i++);assert(to_string(sum)+" ");}
											if (sum>=stoi(Symbols[expression_pointer1->getVal()].getVar()))
												{assert(to_string(sum)+" "+Symbols[expression_pointer1->getVal()].getVar());
												cout<<"Index out of bound\n";FAIL=true;}
											code<<"\tli\t$t7,\t"<<sum*4<<"\n";
											code<<"\tla\t$t1,\t"<<expression_pointer1->getVal()<<"\n";
											code<<"\tadd\t$t1,\t$t1,\t$t7\n";
											code<<"\tlw\t$t0,\t($t1)\n";
											tempArraySize.clear();
										}
									}
									else
									if ("floatA"==temp.getType())
									{
										if (arrays.find(expression_pointer1->getVal()) == arrays.end()) 
										{
											cout << "Symblol \"" << expression_pointer1->getVal() << "\" is not array!\n";
											FAIL=true;
										}
										else
										{
											int shift=0;
											int sum=0;
											int i=0;
											for (auto j:tempArraySize)
												{sum+=j*vectorMaxShift(expression_pointer1->getVal(), i++);assert(to_string(sum)+" ");}
											if (sum>=stoi(Symbols[expression_pointer1->getVal()].getVar()))
												{assert(to_string(sum)+" "+Symbols[expression_pointer1->getVal()].getVar());
												cout<<"Index out of bound\n";FAIL=true;}
											code<<"\tli\t$t7,\t"<<sum*4<<"\n";
											code<<"\tla\t$t1,\t"<<expression_pointer1->getVal()<<"\n";
											code<<"\tadd\t$t1,\t$t1,\t$t7\n";
											code<<"\tl.s\t$f0,\t($t1)\n";
											tempArraySize.clear();
										}
									}
									else
									{
										variable temp=Symbols.at(expression_pointer1->getVal());
										if ("word"==temp.getType())
										{
											code<<"\tlw\t$t0,\t"<<expression_pointer1->getVal()<<"\n";
										}
										else
										{
											code<<"\tl.s\t$f0,\t"<<expression_pointer1->getVal()<<"\n";
										}
									}
					}
				}
			else
				if ("word"==expression_pointer1->getValType())
				{
					code<<"\tli\t$t0,\t"<<stoi(expression_pointer1->getVal())<<"\n";
				}
				else
				{
					code<<"\tl.s\t$f0,\t"<<expression_pointer1->getVal()<<"\n";
				}
			Stack.pop();
			delete expression_pointer1;
			if (Symbols.find($1) == Symbols.end()) 
			{
				cout << "Symblol \"" << $1 << "\" not found!\n";
				FAIL=true;
			}
			else
			{
				if (arrays.find($1) == arrays.end()) 
				{
					cout << "Symblol \"" << $1 << "\" is not array!\n";
					FAIL=true;
				}
				else
				{
					int shift=0;
					int sum=0;
					int i=0;
					for (auto j:tempArraySize)
						{sum+=j*vectorMaxShift($1, i++);assert(to_string(sum)+" ");}
					if (sum>=stoi(Symbols[$1].getVar()))
					{assert(to_string(sum)+" "+Symbols[$1].getVar());
					cout<<"Index out of bound\n";FAIL=true;}
					code<<"\tli\t$t7,\t"<<sum*4<<"\n";
					code<<"\tla\t$t1,\t"<<$1<<"\n";
					code<<"\tadd\t$t1,\t$t1,\t$t7\n";
					if (Symbols[$1].getVarType()=="wordA")
						code<<"\tsw\t$t0,\t($t1)\n";
					else
						code<<"\ts.s\t$f0,\t($t1)\n";
					tempArraySize.clear();
				}
			}
		}
		|IFF expP3 	{
					expression_pointer1 = Stack.top();
					if ("NAME"==expression_pointer1->getValType())
						if (Symbols.find(expression_pointer1->getVal()) == Symbols.end()) 
						{
							cout << "Symblol \"" << expression_pointer1->getVal() << "\" not found!\n";
							FAIL=true;
						}
						else 
						{	
									variable temp=Symbols.at(expression_pointer1->getVal());
									if ("wordA"==temp.getType())
									{
										if (arrays.find(expression_pointer1->getVal()) == arrays.end()) 
										{
											cout << "Symblol \"" << expression_pointer1->getVal() << "\" is not array!\n";
											FAIL=true;
										}
										else
										{
											int shift=0;
											int sum=0;
											int i=0;
											for (auto j:tempArraySize)
												{sum+=j*vectorMaxShift(expression_pointer1->getVal(), i++);assert(to_string(sum)+" ");}
											if (sum>=stoi(Symbols[expression_pointer1->getVal()].getVar()))
												{assert(to_string(sum)+" "+Symbols[expression_pointer1->getVal()].getVar());
												cout<<"Index out of bound\n";FAIL=true;}
											code<<"\tli\t$t7,\t"<<sum*4<<"\n";
											code<<"\tla\t$t1,\t"<<expression_pointer1->getVal()<<"\n";
											code<<"\tadd\t$t1,\t$t1,\t$t7\n";
											code<<"\tlw\t$t0,\t($t1)\n";
											tempArraySize.clear();
										}
									}
									else
									if ("floatA"==temp.getType())
									{
										if (arrays.find(expression_pointer1->getVal()) == arrays.end()) 
										{
											cout << "Symblol \"" << expression_pointer1->getVal() << "\" is not array!\n";
											FAIL=true;
										}
										else
										{
											int shift=0;
											int sum=0;
											int i=0;
											for (auto j:tempArraySize)
												{sum+=j*vectorMaxShift(expression_pointer1->getVal(), i++);assert(to_string(sum)+" ");}
											if (sum>=stoi(Symbols[expression_pointer1->getVal()].getVar()))
												{assert(to_string(sum)+" "+Symbols[expression_pointer1->getVal()].getVar());
												cout<<"Index out of bound\n";FAIL=true;}
											code<<"\tli\t$t7,\t"<<sum*4<<"\n";
											code<<"\tla\t$t1,\t"<<expression_pointer1->getVal()<<"\n";
											code<<"\tadd\t$t1,\t$t1,\t$t7\n";
											code<<"\tl.s\t$f0,\t($t1)\n";
											tempArraySize.clear();
										}
									}
									else
									{
										variable temp=Symbols.at(expression_pointer1->getVal());
										if ("word"==temp.getType())
										{
											code<<"\tlw\t$t0,\t"<<expression_pointer1->getVal()<<"\n";
										}
										else
										{
											code<<"\tl.s\t$f0,\t"<<expression_pointer1->getVal()<<"\n";
										}
									}
						}
					else
						if ("word"==expression_pointer1->getValType())
						{
							code<<"\tli\t$t0,\t"<<stoi(expression_pointer1->getVal())<<"\n";
						}
						else
						{
							code<<"\tl.s\t$f0,\t"<<expression_pointer1->getVal()<<"\n";
						}
					code<<"\tli\t$t1,\t1\n";
					code<<"\tli\t$t4,\t1\n";// flaga ze nie wejdzie w elsa jesli sie nie uruchomia nawiasy
					code<<"\tbne\t$t0,\t$t1,\tif"<<labelSize++<<"\n";
					codes temp;
					temp.code=code.str();
					temp.label=string("if")+to_string(labelSize-1);
					codesStack.push( temp ); 
					code.str("");
					Stack.pop();
					delete expression_pointer1;
					}
		|ELS 		{
						code<<"\tli\t$t1,\t0\n";
						code<<"\tbeq\t$t4,\t$t1,\telse"<<labelSize++<<"\n"; // flaga ze nie wejdzie w elsa jesli sie nie uruchomia nawiasy
						codes temp;
						temp.code=code.str();
						temp.label=string("else")+to_string(labelSize-1);
						codesStack.push( temp ); 
						code.str("");
					}
		|WHI 	{
						code<<"\tli\t$t0,\t1\n";
						code<<"WHIS"<<labelSize++<<":\n";
						code<<"\tli\t$t1,\t0\n";
						code<<"\tbeq\t$t0,\t$t1,\tWHIE"<<labelSize++<<"\n\n";
						codes temp;
						temp.code=code.str();
						temp.label=string("\tjal\tWHIS")+to_string(labelSize-2)+string("\nWHIE")+to_string(labelSize-1);
						temp.label2=string("WHIE")+to_string(labelSize-1);
						codesStack.push( temp ); 
						code.str("");
					}
		|'{' begin '}'	{
							if (codesStack.size()>0)
							{
								
								codes temp=codesStack.top();
								codesStack.pop();
								stringstream tempss;
								tempss<<temp.code;
								//tempss<<"#to jest w nawiasach {}\n"; // dla zabawy
								tempss<<code.str(); // doklejam nowo stworzony kod z nawiasow 
								tempss<<"\tli\t$t4,\t0\n"; // doklejam na wypadek wyjscia z elsa - flaga ze zakonczona nawiasy
								tempss<<temp.label<<":\n"; // doklejenie konca ifa petli etc
								code.str("");
								code<<tempss.str();
							}
							else
								{
									cout<<"Missing something before brackets {}\n Or missing function that you're trying to implement is already declarated\n";
									FAIL=true;
								}
						}
		
		|FUN NAME 	{
						if (functions.find($2) == functions.end()) 
						{
							//funckja zostanie dodana w srtodku kodu i ominieta przez ponizszy skok
							code<<"\tli\t$t0,\t0\n\tli\t$t1,\t0\n\tbeq\t$t0,\t$t1,\tomit"<<labelSize++<<"\n";
							code<<"fun_"<<$2<<":\n";
							code<<"\taddi\t$sp,\t$sp,\t-4\n\tsw\t$ra,\t0($sp)\n\n";
							codes temp;
							temp.code=code.str();
							temp.label=string("\tlw\t$ra,\t0($sp)\n\tadd\t$sp,\t$sp,\t4\n\tjr\t$ra\n\nomit")+to_string(labelSize-1);
							codesStack.push( temp ); 
							code.str("");
							functions[$2]=1;
							assert("dodano funkcje "+string($2)+"\n");
						}
						else
						{	// funkcja just jest zostanie wywolana
							code<<"\tjal\tfun_"<<$2<<"\n";
						}
					}
		|expP3		{
					assert("samotne wyrazenie albo warunek petli/ifa\n");
					if (codesStack.size()>0)
					{
						bool ifint=false;
						expression_pointer1 = Stack.top();
						if ("NAME"==expression_pointer1->getValType())
							if (Symbols.find(expression_pointer1->getVal()) == Symbols.end()) 
							{
								cout << "Symblol \"" << expression_pointer1->getVal() << "\" not found!\n";
								FAIL=true;
							}
							else 
							{
									variable temp=Symbols.at(expression_pointer1->getVal());
									if ("wordA"==temp.getType())
									{
										if (arrays.find(expression_pointer1->getVal()) == arrays.end()) 
										{
											cout << "Symblol \"" << expression_pointer1->getVal() << "\" is not array!\n";
											FAIL=true;
										}
										else
										{
											ifint=true;
											int shift=0;
											int sum=0;
											int i=0;
											for (auto j:tempArraySize)
												{sum+=j*vectorMaxShift(expression_pointer1->getVal(), i++);assert(to_string(sum)+" ");}
											if (sum>=stoi(Symbols[expression_pointer1->getVal()].getVar()))
												{assert(to_string(sum)+" "+Symbols[expression_pointer1->getVal()].getVar());
												cout<<"Index out of bound\n";FAIL=true;}
											code<<"\tli\t$t7,\t"<<sum*4<<"\n";
											code<<"\tla\t$t1,\t"<<expression_pointer1->getVal()<<"\n";
											code<<"\tadd\t$t1,\t$t1,\t$t7\n";
											code<<"\tlw\t$t0,\t($t1)\n";
											tempArraySize.clear();
										}
									}
									else
									if ("floatA"==temp.getType())
									{
										if (arrays.find(expression_pointer1->getVal()) == arrays.end()) 
										{
											cout << "Symblol \"" << expression_pointer1->getVal() << "\" is not array!\n";
											FAIL=true;
										}
										else
										{
											int shift=0;
											int sum=0;
											int i=0;
											for (auto j:tempArraySize)
												{sum+=j*vectorMaxShift(expression_pointer1->getVal(), i++); assert(to_string(sum)+" ");}
											if (sum>=stoi(Symbols[expression_pointer1->getVal()].getVar()))
												{assert(to_string(sum)+" "+Symbols[expression_pointer1->getVal()].getVar());
												cout<<"Index out of bound\n";FAIL=true;}
											code<<"\tli\t$t7,\t"<<sum*4<<"\n";
											code<<"\tla\t$t1,\t"<<expression_pointer1->getVal()<<"\n";
											code<<"\tadd\t$t1,\t$t1,\t$t7\n";
											code<<"\tl.s\t$f0,\t($t1)\n";
											tempArraySize.clear();
										}
									}
									else
									{
									variable temp=Symbols.at(expression_pointer1->getVal());
										if ("word"==temp.getType())
										{
											ifint=true;
											code<<"\tlw\t$t0,\t"<<expression_pointer1->getVal()<<"\n";
										}
										else
										{
											code<<"\tl.s\t$f0,\t"<<expression_pointer1->getVal()<<"\n";
										}
									}
							}
						else
							if ("word"==expression_pointer1->getValType())
							{
								ifint=true;
								code<<"\tli\t$t0,\t"<<stoi(expression_pointer1->getVal())<<"\n";
							}
							else
							{
								code<<"\tl.s\t$f0,\t"<<expression_pointer1->getVal()<<"\n";
							}
						Stack.pop();
						delete expression_pointer1;
						//dla while'a
						codes temp=codesStack.top();
						codesStack.pop();
						temp.code+=string("WHISW")+to_string(labelSize++)+string(":\n");
						if (ifint)
							{code<<"\tli\t$t1,\t0\n";
							code<<"\tbeq\t$t0,\t$t1,\t"<<temp.label2<<"\n\n";
							}
							else
							{code<<"\tl.s\t$f1,\t0\n";
							code<<"\tbeq\t$f0,\t$f1,\t"<<temp.label2<<"\n\n";
							}
						temp.label=string("\tjal\tWHISW")+to_string(labelSize-1)+string("\n")+temp.label2;
						codesStack.push(temp);
					}
					else
					{
						cout<<"Do something with that variable!!\n";
						FAIL=true;
					}
					}
		|STU NAME '{' basic '}'	{
									assert("deklaracja structury"); 
									if (structs.find($2) == structs.end())
									{
										structs[$2]=structTypes;
										structsTypes[$2]=structTypesTypes;
									}
									else
									{
										cout<<"Warning: Struct "<<$2<<" is already declarated - declaration omitted\n";
									}
									structTypes.clear(); 
									structTypesTypes.clear(); 
								}
		|STU NAME NAME			{
									assert("stworznie zmiennej struct");
									create_struct($2,$3);
								}
		;
		
basic	:INT NAME ';'	{assert("struct int"); structTypes.push_back($2); structTypesTypes.push_back("word"); }
		|DOU NAME ';' 	{assert("struct dou"); structTypes.push_back($2); structTypesTypes.push_back("float");}
		|STU NAME NAME ';' 	{assert("struct stu"); structTypes.push_back($3); structTypesTypes.push_back($2);}
		
		|INT NAME array ';' {
								structTypes.push_back(string(".")+$2); structTypesTypes.push_back("wordA");
								arrays[string(".")+$2]=tempArraySize;
							tempArraySize.clear();
						}
		
		|DOU NAME array ';' {
								structTypes.push_back(string(".")+$2); structTypesTypes.push_back("floatA");
								arrays[string(".")+$2]=tempArraySize;
							tempArraySize.clear();
						}
		
		|basic basic {}
		;			
		
expP3		:expP2			{assert("EXP3 Z EXP2"); }
		|expP3 '&' expP3{assert("&"); stack_operator('&'); }
		|expP3 '|' expP3{assert("|"); stack_operator('|');}
		|expP3 '?' expP3{assert("?"); stack_operator('?');}
		|expP3 '<' expP3{assert("<"); stack_operator('<');}
		|expP3 '>' expP3{assert(">"); stack_operator('>');}
		|expP3 '!' expP3{assert("!"); stack_single_operator('!');}
		;
		
		
expP2		:expP1			{assert("expP1"); }
		|expP2 '+' expP2{assert("+"); stack_operator('+');}
		|expP2 '-' expP2{assert("-"); stack_operator('-');}
		;
		
expP1		:value			{ assert("VALUE"); }
		|expP1 '*' expP1{assert("*");	stack_operator('*');}
		|expP1 '/' expP1{assert("/");	stack_operator('/');}
		;
			
value		:IVAL		{assert("ival   ");	Stack.push(new expression(to_string($1), "word")); }
		|DVAL		{assert("dval   ");	Stack.push(new expression(to_string($1), "float")); 	}
		|NAME		{assert("name   "); Stack.push(new expression($1, "NAME")); }
		|NAME array {assert("name   ");	Stack.push(new expression($1, "NAME")); }
		|'#' NAME  	{
							if (Symbols.find($2) == Symbols.end())
							{
								cout<<"Array doesn't exist\n";
								FAIL=true;
							}
							else
							{
								Stack.push(new expression(Symbols[$2].getVar(), "word"));
							}
					}
					
		|'!'expP3	{assert("!"); 		stack_single_operator('!');}
		|'('expP3')'{assert("nawiasy"); }
		;
%%
int main(int argc, char* argv[])
{
	if (argc>1)
	{
		yyin.open(argv[1]);
		if (!yyin.is_open())
		{
			cout << "Blad\n";
			return INFILE_ERROR;
		}
		if (argc>2)
		{
			yyout.open(argv[2]);
			if (!yyout.is_open())
			{
				cout << "Blad\n";
				return OUTFILE_ERROR;
			}
		}
	}
	yyparse();
	if (FAIL)
	{
		cout<<"COMPILATION FAIL\n";
		return 1;
	}
	if (codesStack.size()>0)
	{
		cout<<"Remaining brackets after code block! - Compilation error!\n";
	}
	assert(showStack);
	stringstream out;
	out<<saveSymbols();
	out<<".text\n"<<code.str()<<"\n\n\tli\t$v0,\t10\n\tsyscall\n";
	ofstream program;
	program.open("program.asm");
	program<<out.str();
	program.close();
	//cout<<out.str();
	cout<<"Compilation complete\n";
	return 0;
}
// trzeba dorobic przyrownanie i negacje

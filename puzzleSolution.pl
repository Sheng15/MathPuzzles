%  File       :    proj2.pl
%  Author     :    Sheng Tang
%  StudentID  :    841170
%  Purpose    :    Solve a math puzzle by Prolog, which is a square grid of 
%				   squares,each to be filled in with a single digit 1 to 9,
%                  it must satisfying these constraints:
%                  (1)each row and each column contains no repeated digits;
%                  (2)all squares on the diagonal line from upper left to 
%                     lower right contain the same value;
%                  (3)the heading of each row and column holds either the sum
%					   or the product of all the digits in that row or column
%				
%%%%%%%%%%%%%%%%%%%%%%%%%%   Method   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%  my method mainly incloudes two parts.                                      %
%  (1) choose rows that have least possibilities and fill them recursively.   %
%  (2) check the validity after all Rows have been filled.                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% load the functions transpose for later use
:- ensure_loaded(library(clpfd)).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&%%%%%%%%%%%
%                     Define Math constraints                                 &
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&



% check whether a list is an interger list and all members are between 1 to 9,
% use buildin between function check all the element from head to tail.
% [] is regarded as true, which is not purely logical.
is_integer_1_to_9([]) :-!.
is_integer_1_to_9([Head|Tail]) :-
	between(1,9,Head),
	is_integer_1_to_9(Tail).


% a helper function to get the product of all elements in the list.
% product of empty list is regarded as 1, which is not purely logical either.
% In order to improve efficiency, no check that whether all elements are numbers
% has been implemented! 
product([],1) :-!.
product([Head|Tail],Product) :-
	product(Tail,Total),
	Product is Head*Total.

% check whether a list can be an valid row or column in the puzzle.
% three math constraints are checked:
% (1) all elements in the tail is a digital between 1-9;
% (2) no repeated digital in tail,
% (3) the head holds either the sum or the product of all elements in tail.
% buildin all_distinct function, sum_list function and helper function product are used.
math_constraint([Head|Tail]) :-
	is_integer_1_to_9(Tail),
	all_distinct(Tail),
	(sum_list(Tail,Head);product(Tail,Head)).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&%%%%%%%%%%%
%        choose a Row with Least Possibilities to Fill                        &
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&



% for a given row, bind digitals 1-9 to its variables. If the row satisfies 
% math constraints defined above, it can be a possible solution. 
possible_row(Row,FilledRow) :-
	math_constraint(Row),
	Row=FilledRow.

% use buildin findall function to put all possibility of a row in a list.
% the number of possibility equals to the length of this list.
count_possibility(Row,Count) :-
	findall(FilledRow,possible_row(Row,FilledRow),PossibleRows),
	length(PossibleRows,Count).

% for a given rows list, find the best row which is the row that has the 
% least number of possibilities to be filled first. The possibilities of
% each row are counted and compared to find the best one.
choose_best_tofill([Head|Tail],BestRow):-
	% count the possibilities of head
	count_possibility(Head,Count),
	% use that count to find best row recursively.
	choose_best_tofill(Tail,Count,Head,BestRow).

% if there if more row in the list, what found now is the best row.
choose_best_tofill([],_,BestRow,BestRow).

% loop each row and store the count in the Minimum variable
% if there is any row that has less possibilities than the minumum one
% update minimum and update the CurrentBestRow.
choose_best_tofill([Head|Tail],Minmun,CurrentBestRow,BestRow) :-

	count_possibility(Head,Count),
	(
		Count<Minmun ->
		UpdateCurrentBestRow = Head,
		UpdateMinmum = Count
	;	UpdateCurrentBestRow = CurrentBestRow,
		UpdateMinmum = Minmun
		),
	choose_best_tofill(Tail,UpdateMinmum,UpdateCurrentBestRow,BestRow).


% for a given rows list, fill the row with least possibilities recursively.
% stop filling when the list is an empty list.
fill([]).
fill(RowsAndColumns) :-
	% use buildin exclude function and ground function to filter 
	% rows that has already been filled.
	exclude(ground(),RowsAndColumns,RowsToFill),

	% choose the best row to fill 
	choose_best_tofill(RowsToFill,BestRow),
	% get the list of all possible ways to fill this row.
	findall(FilledRow,possible_row(BestRow,FilledRow),PossibleRows),

	% choose one of the possible ways and fill the row 
	member(Row,PossibleRows),
	BestRow = Row, 
	% remove the row that has been filled.
	exclude(==(BestRow),RowsToFill,Remain_to_fill),

	% keep filling all the row remaining to be filled.
	fill(Remain_to_fill).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&%%%%%%%%%%%
%                   unifying squares on the diagonal                          &
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&



% a helper function to get the first elements of the first 
% list of a list of lists. 
first_elem([Head|Tail],X) :-
	nth0(0,Head,X).

% a helper function that pop the first row from a given puzzle.
% i.e. for a puzzle [[0，1，2],[3，_，_],[4，_,_]],we get 
% [[3，_,_],[4，_,_]] because we do not need to check the first row.
pop_first_list([],[]).
pop_first_list([Head|Tail],Tail).

% a helper function to pop the first elements of all lists in a list of lists.
% stop when there is no list in the list of lists.
pop_first_elem([],[]) :-!.
% discard empty list in the list of lists.
pop_first_elem([[]|Ls],L) :-
    pop_first_elem(Ls,L).
% discard list that has only one element in this list of lists.
pop_first_elem([[_]|Ls],L) :-
    pop_first_elem(Ls,L).
% pop first elemnt recursively.
pop_first_elem([[_,H|T]|Ls],[[H|T]|L]) :-
    pop_first_elem(Ls,L).

% remove all headings for a given puzzle.
% achieved by using two helper function defined above in two steps.
% (1) pop first list from the puzzle, which contains the none meaning top left corner
%	  and all headings in the top.
% (2) pop all heading form the rest rows.
remove_headings(Puzzle,NewPuzzle):-
	pop_first_list(Puzzle,Ls),
	pop_first_elem(Ls,NewPuzzle).

% check whether the diagonal of a given matrix contains same element.
% stop when it is empty or the matrix has only one element .
diagonal([]).
diagonal([_]).
diagonal([[H|T]|Tail]) :-
	% the first element of the initial matrix is H, if after removing all the 
	% headings, the first element of the new matrix remains H, the diagonal 
	% contains same element. check it recursively.
	pop_first_elem(Tail,Ls),
	first_elem(Ls,H),
	diagonal(Ls).

% for a given puzzle, remove all headings and check whether the elements 
% in the diagonal of the matrix we get are all same.   
is_diagonal_all_equal(Puzzle) :-
	remove_headings(Puzzle,Rows),
	diagonal(Rows).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&%%%%%%%%%%%
%                          Solve  the 	Puzzle                                &
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&



% fill the puzzle in 4 steps:
% (1) unifying squares on the diagonal;
% (2) remove the row that contains the none meaning top left corner
%	  and all headings in the top;
% (3) fill the best row recursively;
% (4) check the validity of a solution.
puzzle_solution(Puzzle) :-
	is_diagonal_all_equal(Puzzle),
	pop_first_list(Puzzle,Rows),
	fill(Rows),
	is_valid(Puzzle).

% Puzzle is filled row by row and the diagonal has already been unified,
% so the only thing need to be done is check whether all columns satisfy 
% the math constraints and a
% we get columns by building function transpose.
is_valid(Puzzle) :-
	transpose(Puzzle,NewPuzzle),
	pop_first_list(NewPuzzle,Columns),
	maplist(math_constraint,Columns).




% $Id: functions.pl,v 1.3 2016-11-08 15:04:13-08 - - $
/*Amit Khatri (1398993)*/
/*Marcos Chabolla (1437530)*/

not( X ) :- X, !, fail.
not( _ ).


mathfns( X, List ) :-
   S is sin( X ),
   C is cos( X ),
   Q is sqrt( X ),
   List = [S, C, Q].

constants( List ) :-
   Pi is pi,
   E is e,
   Epsilon is epsilon,
   List = [Pi, E, Epsilon].

sincos( X, Y ) :-
   Y is sin( X ) ** 2 + cos( X ) ** 2.

haversine_radians( Lat1, Lon1, Lat2, Lon2, Distance ) :-
   Dlon is Lon2 - Lon1,
   Dlat is Lat2 - Lat1,
   A is sin( Dlat / 2 ) ** 2
      + cos( Lat1 ) * cos( Lat2 ) * sin( Dlon / 2 ) ** 2,
   Dist is 2 * atan2( sqrt( A ), sqrt( 1 - A )),
   Distance is Dist * 3961.

/*Print path based on array (recursive)*/
/*Used graphpaths.pl as reference*/
printpath( [] ) :-
    nl.

printpath( [[Dep, DDTime, DATime], [Arr, ADTime, AATime] | Rest] ) :-
    airport( Dep, Departing_port, _, _),
    airport( Arr, Arriving_port, _, _),
    write( '     ' ), write( 'depart  ' ),
    write( Dep ), write( '  ' ),
    write( Departing_port ),
    print_travel_time( DDTime ), nl,

    write( '     ' ), write( 'arrive  ' ),
    write( Arr ), write( '  ' ),
    write( Arriving_port ),
    print_travel_time( DATime ), nl,
!, printpath( [[Arr, ADTime, AATime] | Rest] ).

printpath( [[Dep, DDTime, DATime], Arr | []] ) :-
    airport( Dep, Departing_port, _, _),
    airport( Arr, Arriving_port, _, _),
    write( '     ' ), write( 'depart  ' ),
    write( Dep ), write( '  ' ),
    write( Departing_port ),
    print_travel_time( DDTime ), nl,

    write( '     ' ), write( 'arrive  ' ),
    write( Arr ), write( '  ' ),
    write( Arriving_port ),
    print_travel_time( DATime ), nl,
    !, true.

/*Distance between two airports*/
/*Convert Lat & Lon to radians*/
/*Call haversine to compure dist*/
distance( AP1,AP2,Distance) :-
    airport(AP1,_,Lat1,Lon1),
    airport(AP2,_,Lat2,Lon2),
    to_radians(Lat1,LatRad1),
    to_radians(Lon1,LonRad1),
    to_radians(Lat2,LatRad2),
    to_radians(Lon2,LonRad2),
    haversine_radians(LatRad1,LonRad1,LatRad2,LonRad2,Miles),
    Distance is Miles.

    

/*Convert degree minutes to radians*/
to_radians(degmin(Deg,Min),Rads) :-
    Rads is (Deg + (Min/60))*(pi/180).
    
/*Convert time to hours*/
to_hours_only( time( Hours, Mins ), Hoursonly ) :-
    Hoursonly is Hours + Mins / 60.


/*Travel time from one airport to another*/
travel_time(Miles,Hours) :-
    Hours is Miles/500.
    

travel( End, End, _, [End], _ ).

/*Using 'shortest path' algorithm*/
/*Used www.cpp.edu: prolog graph theory as a resource*/
/*Also used graphpaths.pl*/
travel( Curr, End, Visited, [[Curr, DepTime, ArrTime] | List],
          DepTimeInHM ) :-
    flight( Curr, End, DepTimeInHM ),
    not( member( End, Visited ) ),
    to_hours_only( DepTimeInHM, DepTime ),
    distance( Curr, End, DistanceMi ),
    travel_time( DistanceMi, DeltaTime ),
    ArrTime is DepTime + DeltaTime,
    ArrTime < 24.0,
    travel( End, End, [End | Visited], List, _).
    
travel( Curr, End, Visited, [[Curr, DepTime, ArrTime] | List],
          DepTimeInHM ) :-
    flight( Curr, Next, DepTimeInHM ),
    not( member( Next, Visited ) ),
    to_hours_only( DepTimeInHM, DepTime ),
    distance( Curr, Next, DistanceMi ),
    travel_time( DistanceMi, DeltaTime ),
    ArrTime is DepTime + DeltaTime,
    ArrTime < 24.0,

    flight( Next, _, NextDepTimeInHM ),
    to_hours_only( NextDepTimeInHM, NextDepTime ),
    TimeDiff is NextDepTime - ArrTime - 0.5,
    TimeDiff >= 0,
travel( Next, End, [Next | Visited], List, NextDepTimeInHM ).
    
formatnum( Digits ) :-
    Digits < 10, print( 0 ), print( Digits ).

formatnum( Digits ) :-
    Digits >= 10, print( Digits ).

print_travel_time( Hoursonly ) :-
    Minsonly is floor( Hoursonly * 60 ),
    Hours is Minsonly // 60,
    Mins is Minsonly mod 60,
    formatnum( Hours ),
    print( ':' ),
    formatnum( Mins ).




/*For zero-fly queries*/
fly( Depart, Depart ) :-
    write( 'Error: Same departure and destination.' ),
    nl,
    !, fail.

/*'Main' case*/
fly( Depart, Arrive ) :-
    airport( Depart, _, _, _ ),
    airport( Arrive, _, _, _ ),

    travel( Depart, Arrive, [Depart], List, _ ),
    !, nl,
    printpath( List ),
    true.

/*Timezone error*/
fly( Depart, Arrive ) :-
    airport( Depart, _, _, _ ),
    airport( Arrive, _, _, _ ),
    write( 'Error: Not possible in the timezone.' ),
    !, fail.
/*Non-existent airport*/
fly( _, _) :-
    write( 'Error: One or more airports does not exists' ), nl,
!, fail.

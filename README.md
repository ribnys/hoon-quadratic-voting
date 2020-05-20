# hoon-quadratic-voting

Voting is sometimes useful for managing decisions and electing leaders within groups or to gauge preferences within a group.  However, standard voting methods can allow voters to voice their preferences, but not the strength of their preferences.  Quadratic voting is a voting system where voters have the ability to vote for multiple options and can indicate the strength of their preference for each option.  Voters are assigned some number of voting credits and can "spend" voting credits among the different voting options, with the cost in voting credits being the square of the number of votes made for each option. Voters can spread their voting credits among different options or concentrate their credits on particular options, with the marginal cost of a vote increasing for each additional vote for a particular option.  I made a couple of cores designed to implement quadratic voting in Hoon, along with some sample code showing how they could work:

- File 1 is a simple quadratic voting procedure where voters send their votes directly to a pollmaker, who tallies them

- File 2 is a quadratic voting procedure allowing anonymous voting as long as voters are not conspiring with the pollmaker (even then, only some information is leaked under certain conditions)

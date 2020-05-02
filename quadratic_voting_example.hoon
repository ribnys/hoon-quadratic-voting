::
:: Hoon implementation of quadratic voting
:: Quadratic voting is a voting system where voters have the ability to vote for
:: multiple options and can indicate the strength of their preference for each
:: option.  Voters are assigned some number of voting credits and can "spend"
:: voting credits among the different voting options, with the cost in voting
:: credits being the square of the number of votes made for each option.
:: This generator contains a core with arms for implementing basic quadratic
:: voting along with some sample code showing how a quadratic voting poll
:: could work. A quadratic poll ("qpoll") consists of a list of cells with a
:: voting option and a description of that option.  A quadratic vote (qvote) is
:: a list of cells containing a voting option and the number of votes made for
:: that option.  The sample code defines a quadratic poll, then some votes are
:: "cast" (checked for validity i.e. that voting credits aren't overspent and
:: that only options in the poll have been voted for), then a "tally" function
:: checks if all the votes are valid and tallies the results.
::
:-  %say
|=  *
:-  %noun
=<
=/  polltitle=tape  "What color should my sigil be?"
=/  colorpoll=qpoll  :~
[%red "A fiery red"]
[%blue "A calming blue"]
[%green "A verdant green"]
[%purple "A royal purple"]
[%orange "An autumnal orange"]
==
::
=/  vote1  ~[[%red 0] [%blue 1] [%green 4] [%purple 9] [%orange 0]]
=/  vote2  ~[[%red 2] [%blue 1] [%green 4] [%purple 3] [%orange 8]]
=/  vote3  ~[[%red 9] [%blue 1] [%green 0] [%purple 1] [%orange 4]]
::
:: use "castqvote" on votes to confirm that votes are valid (vote credits
:: are not overspent and only options in the poll are voted for)
=/  castvote1=qvote  (castqvote [colorpoll vote1])
=/  castvote2=qvote  (castqvote [colorpoll vote2])
=/  castvote3=qvote  (castqvote [colorpoll vote3])
::
:: use "tally" to confirm that the collected votes are valid and sum the
:: votes to get the result
=/  colorpollresult=qresult  (tally colorpoll ~[castvote1 castvote2 castvote3])
::
:: return the poll title, the poll, and the result
[polltitle colorpoll colorpollresult]
::
|%
::
:: an "option" is one of the choices available in a poll
+$  option  @tas
::
:: a "description" describes an option in a poll
+$  description  tape
::
:: "votes" is the number of votes for an option in a quadratic vote made by
:: an individual
+$  votes  @ud
::
:: "votetotal" is the total number of votes for an option in a poll result
+$  votetotal  @ud
::
:: a "qpoll" is a list of options with descriptions of each option"
+$  qpoll  (list [option description])
::
:: a "qvote" is a vote made by an individual containing a list of voting options
:: and the number of votes cast for each option
+$  qvote  (list [option votes])
::
:: a "qresult" is the result of a poll and consists of a list of options and the
:: total number of votes cast for each option
+$  qresult  (list [option votetotal])
::
:: "getoptions" gets the option tags from a qpoll or qvote as a list
++  getoptions
  |=  a=(list [option *])
  =|  options=(list option)
  =|  index=@ud
  ?~  a  ~
  |-
  ^-  (list option)
  ?:  (lth index (lent a))
  $(options [+2:(snag index `(list [option *])`a) options], index +(index))
  (flop options)
::
:: "overspent" returns & if the total vote credits spent by a qvote is over 100,
::  else |.  For quadratic voting, the cost in vote credits is the square of
:: the number of votes made for an option summed over all options.  The number
:: of alloted voting credits could be set to any number here.  If set to "1",
:: the poll becomes a "normal" (non-quadratic) poll.
++  overspent
  |=  a=qvote
  =|  totalusedcredits=@ud
  =|  index=@ud
  |-
  ^-  ?
  ?:  (lth index (lent a))
  %=  $
  ::
  :: Square the number of votes for an option and add that
  :: value to "totalusedcredits"
  totalusedcredits   (add totalusedcredits (pow +3:(snag index `qvote`a) 2))
  index               +(index)
  ==
  ?:  (gth totalusedcredits 100)
  &
  |
::
:: "nonoption" returns & if a qvote contains options not in a qpoll, else |
++  nonoption
  |=  [=qpoll a=qvote]
  =/  options=(list option)  (getoptions qpoll)
  =|  index=@ud
  |-
  ^-  ?
  ?.  (lth index (lent a))
  |
  :: expression below is false if the @tas at index in the qvote
  :: isn't in the options list
  ?.  (lien `(list option)`options |=(b=option =(b +2:(snag index `qvote`a))))
  &
  $(index +(index))
::
:: "castqvote" prepares a vote for casting, making sure vote credits aren't
::  overspent and votes are only for options in the poll
++  castqvote
  |=  [=qpoll a=qvote]
  ^-  qvote
  ?:  (overspent a)
  ~|("vote credits are overspent" !!)
  ?:  (nonoption qpoll a)
  ~|("the vote contains options not available in the poll" !!)
  a
::
:: "sumqvotes" sums the votes for each option in "qpoll" from a list of
:: qvotes "a" and returns a qresult
++  sumqvotes
  |=  [=qpoll a=(list qvote)]
  =/  options=(list option)  (getoptions qpoll)
  =|  indexoptions=@ud
  =|  votesum=@ud
  =/  allvotes  (zing a)
  =|  indexallvotes=@ud
  =|  result=qresult
  ?~  a  !!
  ?~  options  !!
  |-
  ^-  qresult
  ::
  ::  Iterate  over all options:
  ?:  (lth indexoptions (lent options))
  ::
  :: Iterate over all votes:
  ?:  (lth indexallvotes (lent allvotes))
  ::
  ::  If the current option matches the option in a vote:
  ?:  .=  (snag indexoptions `(list option)`options)
      +2:(snag indexallvotes `qvote`allvotes)
  ::
  :: Increase votesum by the vote amount
  %=  $
  votesum        (add votesum +3:(snag indexallvotes `qvote`allvotes))
  indexallvotes   +(indexallvotes)
  ==
  %=  $
  indexallvotes   +(indexallvotes)
  ==
  ::
  :: Add a cell containing the current option and the votesum for that option
  :: from all votes to the qresult "result"
  %=  $
  result          [[(snag indexoptions `(list option)`options) votesum] result]
  votesum         0
  indexallvotes   0
  indexoptions    +(indexoptions)
  ==
  (flop result)
::
:: "tally" checks if a list of qvotes is valid (voting credits are not overspent
:: and only options in the qpoll have been voted for), then sums the qvotes and
:: returns a qresult
++  tally
  |=  [=qpoll a=(list qvote)]
  =|  indexa=@ud
  |-
  ^-  qresult
  ::
  :: make sure all votes are valid (not overspent and only
  :: available options have been voted for):
  ?:  (lth indexa (lent a))
  ?:  (overspent `qvote`(snag indexa `(list qvote)`a))
  ~|("a vote is overspent" !!)
  ?:  (nonoption qpoll `qvote`(snag indexa `(list qvote)`a))
  ~|("an option not available in the poll is present in a vote" !!)
  $(indexa +(indexa))
  (sumqvotes qpoll a)
--

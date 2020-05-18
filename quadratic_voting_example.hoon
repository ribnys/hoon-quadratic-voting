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
=/  poll-title=tape  "What color should my sigil be?"
=/  colorpoll=qpoll  :~  [%red "A fiery red"]
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
:: use "cast-qvote" on votes to confirm that votes are valid (vote credits
:: are not overspent and only options in the poll are voted for)
=/  castvote1=qvote  (cast-qvote [colorpoll vote1])
=/  castvote2=qvote  (cast-qvote [colorpoll vote2])
=/  castvote3=qvote  (cast-qvote [colorpoll vote3])
::
:: use "tally" to confirm that the collected votes are valid and sum the
:: votes to get the result
=/  colorpoll-result=qresult
%+  tally  colorpoll  ~[castvote1 castvote2 castvote3]
::
:: return the poll title, the poll, and the result
:+  poll-title
    `(list [option description])`colorpoll
    colorpoll-result
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
:: "vote-total" is the total number of votes for an option in a poll result
+$  vote-total  @ud
::
:: "qpoll-slice" is an element of a qpoll consisting of an option and
:: a description
+$  qpoll-slice  [=option =description]
::
:: a "qpoll" is a list of options with descriptions of each option"
+$  qpoll  (list qpoll-slice)
::
:: "qvote-slice" is an element of a qvote consisting of an option and the
:: number of votes cast for that option
+$  qvote-slice  [=option =votes]
::
:: a "qvote" is a vote made by an individual containing a list of voting options
:: and the number of votes cast for each option
+$  qvote  (list qvote-slice)
::
:: a "qresult" is the result of a poll and consists of a list of options and the
:: total number of votes cast for each option
+$  qresult  (list [option vote-total])
::
:: "get-options" gets the option tags from a qpoll as a list
++  get-options
  |=  =qpoll
  ^-  (list option)
  %+  turn  qpoll
  |=  b=qpoll-slice  option:b
::
:: "overspent" returns & if the total vote credits spent by a qvote is over 100,
::  else |.  For quadratic voting, the cost in vote credits is the square of
:: the number of votes made for an option summed over all options.  The number
:: of alloted voting credits could be set to any number here.  If set to "1",
:: the poll becomes a "normal" (non-quadratic) poll.
++  overspent
  |=  =qvote
  ^-  ?
  =|  total-used-credits=@ud
  =|  index=@ud
  |-
  ?:  (lth index (lent qvote))
  %=  $
  ::
  :: Square the number of votes for an option and add that
  :: value to "total-used-credits"
  total-used-credits   %+  add  total-used-credits
                       (pow votes:(snag index qvote) 2)
  ::
  index                +(index)
  ==
  ?:  (gth total-used-credits 100)
  &
  |
::
:: "nonoption" returns & if a qvote contains options not in a qpoll, else |
++  nonoption
  |=  [=qpoll =qvote]
  =/  options=(list option)  (get-options qpoll)
  =|  index=@ud
  |-
  ^-  ?
  ?.  (lth index (lent qvote))
  |
  ?.
  :: expression below is false if the @tas at index in the qvote
  :: isn't in the options list
  %+  lien  options
  |=(b=option =(b option:(snag index qvote)))
  &
  $(index +(index))
::
:: "cast-qvote" prepares a vote for casting, making sure vote credits aren't
::  overspent and votes are only for options in the poll
++  cast-qvote
  |=  [=qpoll a=qvote]
  ^-  qvote
  ?:  (overspent a)
  ~|("vote credits are overspent" !!)
  ?:  (nonoption qpoll a)
  ~|("the vote contains options not available in the poll" !!)
  a
::
:: "sum-qvotes" sums the votes for each option in "qpoll" from a list of
:: qvotes "a" and returns a qresult
++  sum-qvotes
  |=  [=qpoll a=(list qvote)]
  ^-  qresult
  =/  options=(list option)  (get-options qpoll)
  =|  index-options=@ud
  =|  votesum=@ud
  =/  allvotes=(list qvote-slice)  (zing a)
  =|  index-allvotes=@ud
  =|  result=qresult
  |-
  ::
  ::  Iterate  over all options:
  ?:  (lth index-options (lent options))
  ::
  :: Iterate over all votes:
  ?:  (lth index-allvotes (lent allvotes))
  ::
  ::  If the current option matches the option in a vote:
  ?:  .=  (snag index-options options)
      option:(snag index-allvotes allvotes)
  ::
  :: Increase votesum by the vote amount
  %=  $
  votesum          %+  add  votesum
                   votes:(snag index-allvotes allvotes)
  ::
  index-allvotes   +(index-allvotes)
  ==
  %=  $
  index-allvotes   +(index-allvotes)
  ==
  ::
  :: Add a cell containing the current option and the votesum for that option
  :: from all votes to the qresult "result"
  %=  $
  result          :_  result
                  :-  (snag index-options options)
                  votesum
  ::
  votesum         0
  index-allvotes  0
  index-options   +(index-options)
  ==
  (flop result)
::
:: "tally" checks if a list of qvotes is valid (voting credits are not overspent
:: and only options in the qpoll have been voted for), then sums the qvotes and
:: returns a qresult
++  tally
  |=  [=qpoll a=(list qvote)]
  =|  index-a=@ud
  |-
  ^-  qresult
  ::
  :: make sure all votes are valid (not overspent and only
  :: available options have been voted for):
  ?:  (lth index-a (lent a))
  ?:  (overspent `qvote`(snag index-a `(list qvote)`a))
  ~|("a vote is overspent" !!)
  ?:  (nonoption qpoll `qvote`(snag index-a `(list qvote)`a))
  ~|("an option not available in the poll is present in a vote" !!)
  $(index-a +(index-a))
  (sum-qvotes qpoll a)
--

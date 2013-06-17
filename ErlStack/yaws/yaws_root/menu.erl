-module(menu).
-compile(export_all).
-description("This module contains the code to generate the menu in all the pages."
	     "This gives flexibility to change the menu for all pages from one place").

get_menu() ->
     {table,[{style,"text-align:center"}],
      [
       {tr,[],
	[
	 {td,[{width,"300px"}],
	  {a,[{href,"localhost:8081"}],
	   {h1,[],"Home"}
	  }
	 },
	 {td,[{width,"300px"}],{h1,[],"Containers"}},
	 {td,[{width,"300px"}],{h1,[],"VMs"}}
	]
       }
      ]
     }.

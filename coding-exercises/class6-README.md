# SIO221a_Github_code
 Repo for SIO221a

Class 6 coding exercise

*Split up into working teams consisting of 2 groups of 2-3 people. Each team should be all MATLAB or all Python.

*Group 1: write a function called OrthogDemo_[your inits or group name].
	*function takes two inputs, n and m.
	*function outputs a structure "out" with the following fields: 
		*time: a time vector, 0:0.01:(2 pi) 
		*wave1: cos(m*time)
		*wave2: cos(n*time)
		*product = wave1 * wave2
		*integral = \int_0^2*pi wave1 * wave2 dt
	*push this to Github under codingexercises / class6

*Group 2: You will call group 1's function and prove the orthogonality relationship we showed last time for a few values of n,m.
	*choose n,m (choose at least one pair n = m and one where they are not equal)
	*call your group 1's function
	*make a plot with three vertical panels: time on each goes from 0 to 2 * pi.  Panel a plots wave 1, panel b plots wave 2, panel c plots the product.
	*the title shows n, m and out.integral.
	*verify integral = nonzero (what is the value?) for n=m and 0 for n=m
	
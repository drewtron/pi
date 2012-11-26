package com.glgroup.search.util;


public class Pair<Double, type> implements Comparable<Pair<Double, type>> {
	double score;
	type value;

	public Pair(double score, type value) {
		this.score = score;
		this.value = value;
	}

	public double getScore() {
		return score;
	}

	public type getValue() {
		return value;
	}
 
	@Override
	public int compareTo(Pair arg1) {
		Pair p2 = arg1;
		if (this.score > p2.score) {
			return -1;
		} else if (this.score == p2.score) {
			return 0;
		}
		return 1;
	}

	public int compare(Object arg0, Object arg1) {
		Pair p1 = (Pair) arg0;
		Pair p2 = (Pair) arg1;

		if (p1.score > p2.score) {
			return -1;
		} else if (p1.score == p2.score) {
			return 0;
		}
		return 1;
	}
}

BEGIN {
    printf "FilterCurve:"
}

{
    printf " f%d=\"%f\" v%d=\"%f\"", NR - 1, $1, NR - 1, $2 - 87.123894
}

END {
    print " FilterLength=\"8191\" InterpolateLin=\"0\" InterpolationMethod=\"B-spline\""
}

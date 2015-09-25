#!/usr/bin/env bash

printf -v TAB "\t"
printf -v NL "\n"
printf -v DQ '"'
original_IFS="${IFS}"

csv2tsv() {
  local cont="no"   # whether continue from prev cell or prev line (buffer might be empty when col is empty)
  local buffer=""
  local next_delim=""
  local -a row=()

  while read -d "${NL}" line; do
    line="${line//${TAB}/\t},EOS"  # to keep last empty column, add dummy EOS
    # NOTE: Since read with custom IFS drop trail IFS if the trail IFS is only IFS in the input line, so set IFS and soon restore original IFS. WHY?
    IFS=","
    local cols=(${line})
    IFS="${original_IFS}"
    unset cols[${#cols[@]}-1]  # then remove dummy EOS

    for col in "${cols[@]}"; do
      if [ "${cont}" == "no" ]; then
        if [ "${col}" != "${col#${DQ}}" ]; then  # begin with double-quote?
          col="${col#${DQ}}"
          col="${col//${DQ}${DQ}/${TAB}}"  # to detect last double-quote is converted or not, use TAB as place holder
          if [ "${col}" != "${col%${DQ}}" ]; then  # end with double-quote?
            # ,"hoge",
            col="${col%${DQ}}"
            row[${#row[@]}]="${col//${TAB}/${DQ}}"
          else
            # ,"hoge,
            buffer="${col//${TAB}/${DQ}}"
            next_delim=","
            cont="yes"
          fi
        else
          # ,hoge,
          col="${col//${DQ}${DQ}/${DQ}}"
          row[${#row[@]}]="${col}"
        fi
      else
        col="${col//${DQ}${DQ}/${TAB}}"  # to detect last double-quote is converted or not, use TAB as place holder
        if [ "${col}" != "${col%${DQ}}" ]; then  # end with double-quote?
          # ... ,hoge",
          col="${col%${DQ}}"
          row[${#row[@]}]="${buffer}${next_delim}${col//${TAB}/${DQ}}"
          cont="no"
          next_delim=","
        else
          # ... ,hoge,
          buffer="${buffer}${next_delim}${col//${TAB}/${DQ}}"
          next_delim=","
        fi
      fi
    done

    if [ "${cont}" == "no" ]; then
      (IFS="${TAB}"; echo "${row[*]}")
      row=()
    else
      next_delim=""
      buffer="${buffer}\\n"
    fi
  done
}

csv2tsv

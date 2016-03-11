#!/bin/bash

# get the barcode list from json file
cat BarCodeList.json | jq '.[]' | sed 's/"//g' | sort > shoppinglist
while read ONE_LINE; do
    # if the count is larger than one, split it
    if [ ${#ONE_LINE} -gt 10 ]; then
        for(( i=1; i<=${ONE_LINE:11}; i++ )); do
            sed -i '1i'${ONE_LINE:0:10} shoppinglist
        done
        LINE_NUM=`grep -n $ONE_LINE shoppinglist | cut -d ":" -f 1`
        sed -i $LINE_NUM'd' shoppinglist
    fi
done < shoppinglist
# count each barcode
sort shoppinglist | uniq -c > shoppinglist_new


# get the discount list from json file
cat BargainOffer.json | jq '.discount | .barcode | .[]' | sed 's/"//g' > discountlist
# get the extra offer list from json file
cat BargainOffer.json | jq '.extra | .barcode | .[]' | sed 's/"//g' > extralist
# write offer info to shoppinglist_new and re-order
while read NEW_LINE; do
    BARCODE=${NEW_LINE##* }
    if [ `grep $BARCODE extralist` ] ; then
        # no matter only "extra", or both "extra" and "discount", it can only be "extra"
        sed -i "s/$NEW_LINE/2 $NEW_LINE/g" shoppinglist_new
        continue;
    elif  [ `grep $BARCODE discountlist` ]; then
        sed -i "s/$NEW_LINE/1 $NEW_LINE/g" shoppinglist_new
    else
        sed -i "s/$NEW_LINE/0 $NEW_LINE/g" shoppinglist_new
    fi
done < shoppinglist_new
sort shoppinglist_new > shoppinglist
#rm shoppinglist_new


# compute the price and print them out
echo "***<没钱赚商店>购物清单***"
TOTAL_SUM=0
TOTAL_SAVE=0
flag=0
while read NEW_LINE; do
    # get count and barcode
    TYPE=${NEW_LINE%% *}
    COUNT=`echo $NEW_LINE | cut -d " " -f 2`
    BARCODE=${NEW_LINE##* }
    NAME=`cat ProductInfo.json | jq ".$BARCODE.name" | sed 's/"//g'`
    UNIT=`cat ProductInfo.json | jq ".$BARCODE.unit" | sed 's/"//g'`
    PRICE=`cat ProductInfo.json | jq ".$BARCODE.price" | sed 's/"//g'`
    case $TYPE in
    0)  # no offer
        SUM=`echo $COUNT*$PRICE |bc`
        echo "名称:$NAME，数量：$COUNT$UNIT，单价：$PRICE(元)，小计：$SUM (元)"
        ;;
    1)  # discount
        SUM=`echo $COUNT*$PRICE*0.95 |bc`
        SAVE=`echo $COUNT*$PRICE*0.05 |bc`
        TOTAL_SAVE=`echo $TOTAL_SAVE+$SAVE |bc`
        echo "名称:$NAME，数量：$COUNT$UNIT，单价：$PRICE(元)，小计：$SUM (元)，节省：$SAVE(元)"
        ;;
    2)  # buy 3, get 1 free
        SUM=`echo $COUNT/3*2*$PRICE+$COUNT%3*$PRICE |bc`
        if [ $flag -eq 0 ]; then
            flag=1
            echo "-------------------"
            echo "买二赠一商品："
        fi
        echo "名称:$NAME，数量：$COUNT$UNIT，单价：$PRICE(元)，小计：$SUM(元)"
        ;;
    *)  echo "this should not happen"
        ;;
    esac
    TOTAL_SUM=`echo $TOTAL_SUM+$SUM |bc`
done < shoppinglist
echo "-------------------"
echo "总计：$TOTAL_SUM(元)"
if [ `echo "$TOTAL_SAVE>0" |bc` -eq 1 ]; then
    echo "节省：$TOTAL_SAVE(元)"
fi
echo "********************"

exit 0

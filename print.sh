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


# get the product information and print them out
echo "***<没钱赚商店>购物清单***"
TOTAL_SUM=0
TOTAL_SAVE=0
while read NEW_LINE; do
    # get count and barcode
    COUNT=${NEW_LINE%% *}
    BARCODE=${NEW_LINE##* }
    NAME=`cat ProductInfo.json | jq ".$BARCODE.name" | sed 's/"//g'`
    UNIT=`cat ProductInfo.json | jq ".$BARCODE.unit" | sed 's/"//g'`
    PRICE=`cat ProductInfo.json | jq ".$BARCODE.price" | sed 's/"//g'`
    if [ `grep $BARCODE extralist` ] ; then
        # no matter only "extra", or both "extra" and "discount", it can only be "extra"
        #sed -i "s/$NEW_LINE/$NEW_LINE extra/g" shoppinglist_new
        # buy 3, get 1 free
        REMAINDER=`echo $COUNT/3 |bc`
        SUM=`echo $COUNT*$PRICE-$REMAINDER*$PRICE |bc`
        echo "-------------------"
        echo "买二赠一商品："
        echo "名称:$NAME，数量：$COUNT$UNIT，单价：$PRICE(元)，小计：$SUM(元)"
        echo "-------------------"
        continue;
    elif  [ `grep $BARCODE discountlist` ]; then
        #sed -i "s/$NEW_LINE/$NEW_LINE discount/g" shoppinglist_new
        SUM=`echo $COUNT*$PRICE*0.95 |bc`
        SAVE=`echo $COUNT*$PRICE*0.05 |bc`
        echo "名称:$NAME，数量：$COUNT$UNIT，单价：$PRICE(元)，小计：$SUM (元)，节省：$SAVE(元)"
    else
        #echo "no offer:"$BARCODE
        SUM=`echo $COUNT*$PRICE |bc`
        echo "名称:$NAME，数量：$COUNT$UNIT，单价：$PRICE(元)，小计：$SUM (元)"
    fi
    TOTAL_SUM=`echo $TOTAL_SUM+$SUM |bc`
    TOTAL_SAVE=`echo $TOTAL_SAVE+$SAVE |bc`
done < shoppinglist_new

echo "-------------------"
echo "总计：$TOTAL_SUM(元)"
echo "节省：$TOTAL_SAVE(元)"
echo "********************"

exit 0

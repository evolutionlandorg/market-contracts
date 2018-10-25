const ClockAuction = artifacts.require('ClockAuction');

const auction_address = '0x3a0aa8bce3c00305f9024bb46bf0f2d328129a79';
const startTokenId = 18998906514627227268043541001230492221534399580350777576391476909546099704093;
const endingtokenId = 18998906514627227268043541001230492221534399580350777576391476909546099704117;


module.exports = async () => {
    let auction = await ClockAuction.at(auction_address);

    for(let index = startTokenId; index <= endingtokenId; index++) {
        await auction.cancelAuction(index);
        console.log('individual done!');
    }
    console.log('DONE');
}
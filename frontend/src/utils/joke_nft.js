
export const safeMint = async (jokeNftContract, performActions, uri) => {
    try {
        await performActions(async (kit) => {
            const { defaultAccount } = kit;

            console.log(jokeNftContract, uri);

            // return;

            await jokeNftContract.methods.safeMint(defaultAccount, uri).send({ from: defaultAccount });
        });

        return true;
    } catch (e) {
        console.log({ e });

        return e;
    }
};

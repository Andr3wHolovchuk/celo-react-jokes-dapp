import { useCallback, useEffect, useState } from "react";
import { getAddressSpec, getSpec, setDislike, setLike } from "../../utils";
import { allCategories, allJokes } from "../../utils/joke";

const Leaderboard = ({ jokeContract, address }) => {

    const [allJokesArray, setAllJokesArray] = useState([]);

    const [allCategories_, setAllCategories] = useState([]);

    const setCategories = useCallback(async () => {
        setAllCategories(await allCategories(jokeContract))
    }, [jokeContract]);

    const getAllJokes = useCallback(async () => {
        const all_jokes = await allJokes(jokeContract);

        let temp = [];

        for (let index in all_jokes) {
            if (parseInt(all_jokes[index].user, 16) !== 0) {
                const spec = await getSpec(index);
                const addressSpec = await getAddressSpec(address);

                let address_likes = addressSpec.ratings.likes,
                    address_dislikes = addressSpec.ratings.dislikes;

                temp.push({
                    index,
                    joke: all_jokes[index],
                    spec: spec,
                    liked: address_likes ? address_likes.includes(parseInt(index)) : false,
                    disliked: address_dislikes ? address_dislikes.includes(parseInt(index)) : false
                });
            }
        }

        temp.sort((a, b) => {
            return (b.spec.likes - b.spec.dislikes) - (a.spec.likes - a.spec.dislikes);
        });

        setAllJokesArray(temp);
    }, [jokeContract, address]);


    const renderJoke = (joke, i) => {
        const specific = joke.joke;
        return (
            <div className="row" key={i}>
                <div className="card col-md-6 mx-auto p-0 my-4">
                    <div className="card-header"><a href={"/profile/" + specific.user }>{specific.user}</a> <small className="float-end">{new
                        Date(parseInt(specific.create_timestamp)).toLocaleDateString()}</small></div>
                    <div className="card-body">
                        <h5 className="card-title">{specific.title}</h5>
                        <p className="card-text">{specific.content}</p>
                        <div className="row actions">
                            <div className="col-md-6 text-center">
                                <button type="button" className={(joke.liked ? "selected " : "") + "btn btn-mkn2 btn-sm like"} onClick={() => setLike(joke.index, address, getAllJokes)}><i
                                    className="fas fa-thumbs-up"></i></button>
                                <span>{joke.spec.likes}</span>
                            </div>
                            <div className="col-md-6 text-center">
                                <button type="button" className={(joke.disliked ? "selected " : "") + "btn btn-mkn3 btn-sm dislike"} onClick={() => setDislike(joke.index, address, getAllJokes)}><i
                                    className="fas fa-thumbs-down"></i></button>
                                <span>{joke.spec.dislikes}</span>
                            </div>
                        </div>
                        <div className="row">
                            <span className="text-end">Category - <a href="">#{allCategories_[specific.category_id]}</a></span>
                        </div>
                    </div>
                </div>
            </div>
        )
    }

    useEffect(() => {
        setCategories();

        getAllJokes();
    }, [jokeContract])

    return (
        <>
            <section className="container-fluid about">
                <div className="row">
                    <div className="col-12 mt-4">
                        <h1 className="text-center text-dark">Best rated jokes</h1>

                        <div className="itd_play">
                            <div className="itd_triangle"></div>
                        </div>
                    </div>
                </div>

                {allJokesArray ?
                    <div id="jokes_container">
                        {allJokesArray.map((v, i) =>
                            renderJoke(v, i)
                        )}
                    </div>

                    :
                    <div></div>
                }

            </section>

            <footer id="footer"></footer>
        </>
    );

};

export default Leaderboard;
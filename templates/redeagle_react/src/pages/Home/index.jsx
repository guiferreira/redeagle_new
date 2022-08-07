import PropTypes from 'prop-types'
import PhoenixLogo from "../../phoenix.png"
import ReactLogo from "../../logo.svg"
import DockerLogo from "../../docker.webp"

export const Home = ({ title }) => {
	return (
		<>
			<header>
				<section className="container">
					<div className="phx-logo">
						<img src={PhoenixLogo} alt="Phoenix Framework" />
					</div>
					<div className="phx-logo">
						<img src={ReactLogo} alt="React" />
					</div>
					<div className="phx-logo">
						<img src={DockerLogo} alt="React" />
					</div>
				</section>
			</header>
			<main className="container">
				<section className="phx-hero">
					<h1>{title}</h1>
					<p>It's not a bird and it's not a plane it's a union of the best Phoenix, React and Docker</p>
				</section>
				<section className="row">
					<article className="column">
						<h2>Resources</h2>
						<ul>
							<li>
								<a href="https://hexdocs.pm/phoenix/overview.html">Guides &amp; Docs</a>
							</li>
							<li>
								<a href="https://github.com/phoenixframework/phoenix">Source</a>
							</li>
							<li>
								<a href="https://github.com/guiferreira/redeagle_new">v0.1.0 Changelog</a>
							</li>
						</ul>
					</article>
					<article className="column">
						<h2>Help</h2>
						<ul>
							<li>
								<a href="https://elixirforum.com/c/phoenix-forum">Forum</a>
							</li>
							<li>
								<a href="https://elixir-slackin.herokuapp.com/">Elixir on Slack</a>
							</li>
							<li>
								<a href="https://discord.gg/elixir">Elixir on Discord</a>
							</li>
						</ul>
					</article>
				</section>
			</main>
		</>
	);
};
Home.defaultProps = {
	title: '',
};

Home.prototype = {
	title: PropTypes.string.isRequired,
};

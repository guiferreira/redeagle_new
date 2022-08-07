import { BrowserRouter, Routes, Route } from 'react-router-dom'
import { Home } from '../pages/Home'

export const Main = () => {
	return (
		<BrowserRouter>
			<Routes>
				<Route exact path="/" element={<Home title={'RedEagle Project'} />}></Route>
				<Route exact path="/login" element={<Home title={'RedEagle Project'} />}></Route>
				<Route exact path="/register" element={<Home title={'RedEagle Project'} />}></Route>
			</Routes>
		</BrowserRouter>
	);
}
